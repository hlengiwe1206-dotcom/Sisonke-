-- SISONKE MVP DATABASE FOUNDATION
create extension if not exists "uuid-ossp";

create type public.user_role as enum ('citizen','community_organiser','organisation_admin','moderator','platform_admin');
create type public.post_type as enum ('community_issue','information','opportunity','help_needed','help_offered','community_action','resource_request');
create type public.content_status as enum ('active','hidden','restricted','removed');
create type public.help_status as enum ('open','matched','in_progress','completed','closed');

create table public.provinces (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique
);

create table public.municipalities (
  id uuid primary key default uuid_generate_v4(),
  province_id uuid references public.provinces(id) on delete cascade,
  name text not null
);

create table public.communities (
  id uuid primary key default uuid_generate_v4(),
  municipality_id uuid references public.municipalities(id) on delete cascade,
  name text not null
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  avatar_url text,
  role public.user_role not null default 'citizen',
  province_id uuid references public.provinces(id),
  municipality_id uuid references public.municipalities(id),
  community_id uuid references public.communities(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  icon text,
  active boolean default true
);

create table public.posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid references public.categories(id),
  type public.post_type not null,
  title text not null,
  content text not null,
  province_id uuid references public.provinces(id),
  municipality_id uuid references public.municipalities(id),
  community_id uuid references public.communities(id),
  status public.content_status default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  status public.content_status default 'active',
  created_at timestamptz default now()
);

create table public.help_requests (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid unique not null references public.posts(id) on delete cascade,
  requester_id uuid not null references public.profiles(id),
  status public.help_status default 'open',
  created_at timestamptz default now()
);

create table public.help_offers (
  id uuid primary key default uuid_generate_v4(),
  help_request_id uuid not null references public.help_requests(id) on delete cascade,
  helper_id uuid not null references public.profiles(id),
  message text,
  status text default 'pending',
  created_at timestamptz default now()
);

create table public.help_connections (
  id uuid primary key default uuid_generate_v4(),
  help_request_id uuid references public.help_requests(id),
  requester_id uuid references public.profiles(id),
  helper_id uuid references public.profiles(id),
  status public.help_status default 'in_progress',
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table public.opportunities (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid unique references public.posts(id) on delete cascade,
  organisation_name text,
  opportunity_type text,
  closing_date date,
  application_url text,
  eligibility_requirements text
);

create table public.reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid references public.profiles(id),
  content_type text not null,
  content_id uuid not null,
  reason text not null,
  notes text,
  status text default 'open',
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;

create policy "Public profiles are readable" on public.profiles for select using (true);
create policy "Users update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Posts are readable" on public.posts for select using (status = 'active');
create policy "Users create own posts" on public.posts for insert with check (auth.uid() = user_id);
create policy "Users update own posts" on public.posts for update using (auth.uid() = user_id);
create policy "Users delete own posts" on public.posts for delete using (auth.uid() = user_id);
create policy "Comments are readable" on public.comments for select using (status = 'active');
create policy "Users create own comments" on public.comments for insert with check (auth.uid() = user_id);

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
