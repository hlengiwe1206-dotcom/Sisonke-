-- ============================================================
-- SISONKE APP
-- MILESTONE 4
-- INFORMATION HUB + OPPORTUNITIES DATABASE
-- ============================================================


-- ============================================================
-- EXTENSION
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- TABLE 1: INFORMATION POSTS
-- ============================================================

create table if not exists public.information_posts (

    id uuid primary key default gen_random_uuid(),

    title text not null,

    description text not null,

    category text not null,

    location text,

    source_name text not null,

    source_url text,

    image_url text,

    is_verified boolean not null default false,

    is_featured boolean not null default false,

    published_at timestamptz,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()

);


-- ============================================================
-- TABLE 2: OPPORTUNITIES
-- ============================================================

create table if not exists public.opportunities (

    id uuid primary key default gen_random_uuid(),

    title text not null,

    organisation text not null,

    description text not null,

    category text not null,

    location text,

    closing_date date,

    source_name text not null,

    source_url text,

    image_url text,

    is_verified boolean not null default false,

    is_featured boolean not null default false,

    published_at timestamptz,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()

);


-- ============================================================
-- INDEXES
-- These make the Home Feed and Opportunities queries faster.
-- ============================================================

create index if not exists information_posts_feed_index
on public.information_posts (
    is_featured desc,
    published_at desc
);


create index if not exists opportunities_feed_index
on public.opportunities (
    is_featured desc,
    closing_date asc
);


create index if not exists information_posts_category_index
on public.information_posts (
    category
);


create index if not exists opportunities_category_index
on public.opportunities (
    category
);


-- ============================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================

alter table public.information_posts
enable row level security;


alter table public.opportunities
enable row level security;


-- ============================================================
-- REMOVE EXISTING CLIENT PRIVILEGES
-- ============================================================

revoke all on table public.information_posts
from anon, authenticated;


revoke all on table public.opportunities
from anon, authenticated;


-- ============================================================
-- GRANT READ-ONLY ACCESS
-- ============================================================

grant select on table public.information_posts
to anon, authenticated;


grant select on table public.opportunities
to anon, authenticated;


-- ============================================================
-- REMOVE OLD POLICIES IF THEY EXIST
-- ============================================================

drop policy if exists
"Public can read verified information posts"
on public.information_posts;


drop policy if exists
"Public can read verified opportunities"
on public.opportunities;


-- ============================================================
-- INFORMATION POSTS POLICY
--
-- Users can ONLY see:
-- 1. Verified information
-- 2. Information with a published date
-- 3. Information published now or in the past
-- ============================================================

create policy
"Public can read verified information posts"

on public.information_posts

for select

to anon, authenticated

using (
    is_verified = true
    and published_at is not null
    and published_at <= now()
);


-- ============================================================
-- OPPORTUNITIES POLICY
--
-- Users can ONLY see:
-- 1. Verified opportunities
-- 2. Published opportunities
-- ============================================================

create policy
"Public can read verified opportunities"

on public.opportunities

for select

to anon, authenticated

using (
    is_verified = true
    and published_at is not null
    and published_at <= now()
);


-- ============================================================
-- UPDATED_AT FUNCTION
-- ============================================================

create or replace function public.update_updated_at_column()

returns trigger

language plpgsql

as $$

begin
    new.updated_at = now();
    return new;
end;

$$;


-- ============================================================
-- INFORMATION POSTS UPDATED_AT TRIGGER
-- ============================================================

drop trigger if exists
update_information_posts_updated_at
on public.information_posts;


create trigger
update_information_posts_updated_at

before update

on public.information_posts

for each row

execute function public.update_updated_at_column();


-- ============================================================
-- OPPORTUNITIES UPDATED_AT TRIGGER
-- ============================================================

drop trigger if exists
update_opportunities_updated_at
on public.opportunities;


create trigger
update_opportunities_updated_at

before update

on public.opportunities

for each row

execute function public.update_updated_at_column();


-- ============================================================
-- REALTIME
--
-- This allows the app to receive future live database updates.
-- ============================================================

alter publication supabase_realtime
add table public.information_posts;


alter publication supabase_realtime
add table public.opportunities;
