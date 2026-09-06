-- ============================================================
-- SISONKE LIVE MVP BACKEND
-- Run this entire file in the Supabase SQL Editor.
-- ============================================================

create extension if not exists "uuid-ossp";

-- ENUMS
do $$ begin
  create type public.user_role as enum ('citizen','community_organiser','organisation_admin','moderator','platform_admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.post_type as enum ('community_issue','information','opportunity','help_needed','help_offered','community_action','resource_request');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.content_status as enum ('active','hidden','restricted','removed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.help_status as enum ('open','matched','in_progress','completed','closed');
exception when duplicate_object then null; end $$;

-- GEOGRAPHY
create table if not exists public.provinces (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique
);

create table if not exists public.municipalities (
  id uuid primary key default uuid_generate_v4(),
  province_id uuid references public.provinces(id) on delete cascade,
  name text not null
);

create table if not exists public.communities (
  id uuid primary key default uuid_generate_v4(),
  municipality_id uuid references public.municipalities(id) on delete cascade,
  name text not null
);

-- USERS
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  avatar_url text,
  role public.user_role not null default 'citizen',
  province_id uuid references public.provinces(id),
  municipality_id uuid references public.municipalities(id),
  community_id uuid references public.communities(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Automatically create a profile when a user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id, first_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'first_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- CATEGORIES
create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  icon text,
  active boolean not null default true
);

-- POSTS
create table if not exists public.posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid references public.categories(id),
  type public.post_type not null,
  title text not null check (char_length(title) between 3 and 120),
  content text not null check (char_length(content) between 10 and 5000),
  province_id uuid references public.provinces(id),
  municipality_id uuid references public.municipalities(id),
  community_id uuid references public.communities(id),
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_created_idx on public.posts(created_at desc);
create index if not exists posts_type_idx on public.posts(type);

-- HELP EXCHANGE
create table if not exists public.help_requests (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid unique not null references public.posts(id) on delete cascade,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  status public.help_status not null default 'open',
  created_at timestamptz not null default now()
);

create table if not exists public.help_offers (
  id uuid primary key default uuid_generate_v4(),
  help_request_id uuid not null references public.help_requests(id) on delete cascade,
  helper_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(message) between 3 and 3000),
  status text not null default 'pending' check (status in ('pending','accepted','declined','withdrawn')),
  created_at timestamptz not null default now(),
  unique(help_request_id, helper_id)
);

create table if not exists public.help_connections (
  id uuid primary key default uuid_generate_v4(),
  help_request_id uuid not null unique references public.help_requests(id) on delete cascade,
  requester_id uuid not null references public.profiles(id),
  helper_id uuid not null references public.profiles(id),
  status public.help_status not null default 'in_progress',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.conversations (
  id uuid primary key default uuid_generate_v4(),
  connection_id uuid not null unique references public.help_connections(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text not null check (char_length(content) between 1 and 4000),
  created_at timestamptz not null default now()
);

-- SAFETY
create table if not exists public.blocked_users (
  id uuid primary key default uuid_generate_v4(),
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(blocker_id, blocked_user_id),
  check (blocker_id <> blocked_user_id)
);

create table if not exists public.reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.profiles(id),
  content_type text not null,
  content_id uuid not null,
  reason text not null,
  notes text,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

-- NOTIFICATIONS
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  related_type text,
  related_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- REALTIME FEED VIEW
create or replace view public.help_request_feed
with (security_invoker = true)
as
select
  hr.id,
  hr.requester_id,
  hr.status,
  hr.created_at,
  p.title,
  p.content,
  c.name as category_name,
  (
    select count(*)::int
    from public.help_offers ho
    where ho.help_request_id = hr.id
      and ho.status = 'pending'
  ) as offer_count
from public.help_requests hr
join public.posts p on p.id = hr.post_id
left join public.categories c on c.id = p.category_id
where p.status = 'active';

-- ACCEPT OFFER TRANSACTION
create or replace function public.accept_help_offer(p_help_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_offer public.help_offers;
  v_request public.help_requests;
  v_connection_id uuid;
begin
  select * into v_offer
  from public.help_offers
  where id = p_help_offer_id
  for update;

  if not found then
    raise exception 'Help offer not found';
  end if;

  select * into v_request
  from public.help_requests
  where id = v_offer.help_request_id
  for update;

  if auth.uid() <> v_request.requester_id then
    raise exception 'Only the requester can accept this offer';
  end if;

  if v_request.status <> 'open' then
    raise exception 'This request is no longer open';
  end if;

  insert into public.help_connections(help_request_id, requester_id, helper_id)
  values (v_request.id, v_request.requester_id, v_offer.helper_id)
  returning id into v_connection_id;

  insert into public.conversations(connection_id)
  values (v_connection_id);

  update public.help_offers
  set status = case when id = v_offer.id then 'accepted' else 'declined' end
  where help_request_id = v_request.id;

  update public.help_requests set status = 'matched'
  where id = v_request.id;

  insert into public.notifications(user_id, type, title, body, related_type, related_id)
  values (
    v_offer.helper_id,
    'help_offer_accepted',
    'Your help offer was accepted',
    'You can now safely connect through Sisonke.',
    'help_connection',
    v_connection_id
  );

  return v_connection_id;
end;
$$;

-- COMPLETE CONNECTION
create or replace function public.complete_help_connection(p_connection_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_connection public.help_connections;
begin
  select * into v_connection from public.help_connections
  where id = p_connection_id for update;

  if not found then raise exception 'Connection not found'; end if;

  if auth.uid() not in (v_connection.requester_id, v_connection.helper_id) then
    raise exception 'Not permitted';
  end if;

  update public.help_connections
  set status = 'completed', completed_at = now()
  where id = p_connection_id;

  update public.help_requests
  set status = 'completed'
  where id = v_connection.help_request_id;
end;
$$;

-- RLS
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.help_requests enable row level security;
alter table public.help_offers enable row level security;
alter table public.help_connections enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.blocked_users enable row level security;
alter table public.reports enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles readable" on public.profiles;
create policy "profiles readable" on public.profiles
for select using (true);

drop policy if exists "profile owner updates" on public.profiles;
create policy "profile owner updates" on public.profiles
for update using (auth.uid() = id);

drop policy if exists "active posts readable" on public.posts;
create policy "active posts readable" on public.posts
for select using (status = 'active');

drop policy if exists "users create own posts" on public.posts;
create policy "users create own posts" on public.posts
for insert with check (auth.uid() = user_id);

drop policy if exists "users update own posts" on public.posts;
create policy "users update own posts" on public.posts
for update using (auth.uid() = user_id);

drop policy if exists "open help requests readable" on public.help_requests;
create policy "open help requests readable" on public.help_requests
for select using (true);

drop policy if exists "users create own help requests" on public.help_requests;
create policy "users create own help requests" on public.help_requests
for insert with check (auth.uid() = requester_id);

drop policy if exists "offers visible to parties" on public.help_offers;
create policy "offers visible to parties" on public.help_offers
for select using (
  helper_id = auth.uid()
  or exists (
    select 1 from public.help_requests hr
    where hr.id = help_request_id and hr.requester_id = auth.uid()
  )
);

drop policy if exists "users create own offers" on public.help_offers;
create policy "users create own offers" on public.help_offers
for insert with check (
  helper_id = auth.uid()
  and exists (
    select 1 from public.help_requests hr
    where hr.id = help_request_id
      and hr.requester_id <> auth.uid()
      and hr.status = 'open'
  )
);

drop policy if exists "connections visible to participants" on public.help_connections;
create policy "connections visible to participants" on public.help_connections
for select using (auth.uid() in (requester_id, helper_id));

drop policy if exists "conversation visible to participants" on public.conversations;
create policy "conversation visible to participants" on public.conversations
for select using (
  exists (
    select 1 from public.help_connections hc
    where hc.id = connection_id
      and auth.uid() in (hc.requester_id, hc.helper_id)
  )
);

drop policy if exists "messages visible to conversation participants" on public.messages;
create policy "messages visible to conversation participants" on public.messages
for select using (
  exists (
    select 1
    from public.conversations c
    join public.help_connections hc on hc.id = c.connection_id
    where c.id = conversation_id
      and auth.uid() in (hc.requester_id, hc.helper_id)
  )
);

drop policy if exists "participants send messages" on public.messages;
create policy "participants send messages" on public.messages
for insert with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.conversations c
    join public.help_connections hc on hc.id = c.connection_id
    where c.id = conversation_id
      and auth.uid() in (hc.requester_id, hc.helper_id)
  )
);

drop policy if exists "users manage blocks" on public.blocked_users;
create policy "users manage blocks" on public.blocked_users
for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

drop policy if exists "users create reports" on public.reports;
create policy "users create reports" on public.reports
for insert with check (reporter_id = auth.uid());

drop policy if exists "users view own notifications" on public.notifications;
create policy "users view own notifications" on public.notifications
for select using (user_id = auth.uid());

drop policy if exists "users update own notifications" on public.notifications;
create policy "users update own notifications" on public.notifications
for update using (user_id = auth.uid());

-- Seed data
insert into public.provinces(name) values
('Eastern Cape'),('Free State'),('Gauteng'),('KwaZulu-Natal'),('Limpopo'),
('Mpumalanga'),('Northern Cape'),('North West'),('Western Cape')
on conflict do nothing;

insert into public.categories(name, icon) values
('Employment & Opportunities','work'),
('Education','school'),
('Community Issues','groups'),
('Help Exchange','handshake'),
('Business & Entrepreneurship','business'),
('Health & Wellness Awareness','favorite')
on conflict do nothing;

-- Realtime publication
do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.help_requests;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.help_offers;
exception when duplicate_object then null;
end $$;
