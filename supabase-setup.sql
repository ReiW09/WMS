create table if not exists public.wms_users (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null check (role in ('admin', 'operator', 'viewer')),
  created_at timestamptz not null default now()
);

create table if not exists public.wms_docs (
  collection text not null check (collection in ('items', 'master', 'cfg', 'tx', 'foto')),
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);

create index if not exists wms_docs_collection_idx on public.wms_docs (collection);

alter table public.wms_users enable row level security;
alter table public.wms_docs enable row level security;

create or replace function public.wms_current_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.wms_users where id = (select auth.uid())
$$;

revoke all on function public.wms_current_role() from public, anon;
grant execute on function public.wms_current_role() to authenticated;

grant select, insert, update, delete on public.wms_users to authenticated;
grant select, insert, update, delete on public.wms_docs to authenticated;

drop policy if exists "WMS users can read own profile" on public.wms_users;
create policy "WMS users can read own profile"
  on public.wms_users for select to authenticated
  using (id = (select auth.uid()) or (select public.wms_current_role()) = 'admin');

drop policy if exists "WMS admins manage profiles" on public.wms_users;
create policy "WMS admins manage profiles"
  on public.wms_users for all to authenticated
  using ((select public.wms_current_role()) = 'admin')
  with check ((select public.wms_current_role()) = 'admin');

drop policy if exists "WMS members read shared data" on public.wms_docs;
create policy "WMS members read shared data"
  on public.wms_docs for select to authenticated
  using (
    (select public.wms_current_role()) in ('admin', 'operator', 'viewer')
    and (collection <> 'cfg' or id <> 'pin' or (select public.wms_current_role()) = 'admin')
  );

drop policy if exists "WMS operators write operational data" on public.wms_docs;
create policy "WMS operators write operational data"
  on public.wms_docs for insert to authenticated
  with check (
    (
      (select public.wms_current_role()) = 'admin'
      and collection in ('items', 'master', 'cfg', 'tx', 'foto')
    )
    or (
      (select public.wms_current_role()) = 'operator'
      and collection in ('master', 'tx', 'foto')
    )
  );

drop policy if exists "WMS operators update operational data" on public.wms_docs;
create policy "WMS operators update operational data"
  on public.wms_docs for update to authenticated
  using (
    (
      (select public.wms_current_role()) = 'admin'
      and collection in ('items', 'master', 'cfg', 'tx', 'foto')
    )
    or (
      (select public.wms_current_role()) = 'operator'
      and collection in ('master', 'foto')
    )
  )
  with check (
    (
      (select public.wms_current_role()) = 'admin'
      and collection in ('items', 'master', 'cfg', 'tx', 'foto')
    )
    or (
      (select public.wms_current_role()) = 'operator'
      and collection in ('master', 'foto')
    )
  );

drop policy if exists "WMS admins delete shared data" on public.wms_docs;
create policy "WMS admins delete shared data"
  on public.wms_docs for delete to authenticated
  using ((select public.wms_current_role()) = 'admin');
