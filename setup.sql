-- Run once in Supabase: SQL Editor -> New query -> paste -> Run.

create table if not exists public.pages (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id         text not null,
  "order"    int  not null default 1,
  asset_path text,
  height     int  not null default 1600,
  notes      text not null default '',
  thumb      text,
  updated_at timestamptz,
  primary key (user_id, id)
);

alter table public.pages enable row level security;

drop policy if exists "own pages" on public.pages;
create policy "own pages" on public.pages
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Private bucket for the page images, one folder per user.
insert into storage.buckets (id, name, public)
values ('pages', 'pages', false)
on conflict (id) do nothing;

drop policy if exists "own page images" on storage.objects;
create policy "own page images" on storage.objects
  for all to authenticated
  using (bucket_id = 'pages' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'pages' and (storage.foldername(name))[1] = (select auth.uid())::text);
