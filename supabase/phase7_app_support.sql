-- SISONKE PHASE 7 - APP SUPPORT
-- Optional view for analytics/future feed use and Realtime posts.
create or replace view public.help_request_feed with (security_invoker=true) as
select hr.id, hr.requester_id, hr.status, hr.created_at, p.title, p.content, c.name as category_name,
  (select count(*)::int from public.help_offers ho where ho.help_request_id=hr.id and ho.status='pending') as offer_count
from public.help_requests hr join public.posts p on p.id=hr.post_id left join public.categories c on c.id=p.category_id
where p.status='active';

do $$ begin alter publication supabase_realtime add table public.posts; exception when duplicate_object then null; end $$;
