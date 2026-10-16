-- ============================================================================
-- Kuwait eVisa demo portal · Supabase schema
-- ----------------------------------------------------------------------------
-- How to use:
--   1. Open your Supabase project, go to the SQL Editor and run this whole file.
--   2. Copy the project URL and the anon public key from Settings > API.
--   3. Paste them into SUPABASE_URL and SUPABASE_ANON_KEY at the top of the
--      script inside index.html, then reload the page over http or https.
--
-- DEMO ONLY. The policies below let anyone who holds the anon key read AND
-- write every row. That is what this brief asked for, and it is also the exact
-- reason this table must never hold real personal data. Before any real use,
-- move writes behind Supabase Auth or an Edge Function and keep only the
-- read-by-reference policy public.
-- ============================================================================

create extension if not exists pgcrypto;

create table if not exists public.kuwait_visas (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique check (code ~ '^[A-Z0-9]{6}$'),
  full_name_en    text not null,
  full_name_ar    text not null default '',
  passport_no     text not null,
  nationality_en  text not null,
  nationality_ar  text not null default '',
  gender          text not null default 'Male' check (gender in ('Male', 'Female')),
  date_of_birth   date,
  profession_en   text not null default '',
  profession_ar   text not null default '',
  visa_type_en    text not null default '',
  visa_type_ar    text not null default '',
  issue_date      date not null default current_date,
  expiry_date     date not null,
  photo_url       text not null default '',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint kuwait_visas_dates_check check (expiry_date >= issue_date)
);

comment on table public.kuwait_visas is
  'Demonstration visa records for the local eVisa status portal. Placeholder data only.';

comment on column public.kuwait_visas.photo_url is
  'Image URL, or a data:image/jpeg;base64 picture uploaded in the console and already resized to 720 px on the longest edge.';

create index if not exists kuwait_visas_code_idx on public.kuwait_visas (code);
create index if not exists kuwait_visas_created_idx on public.kuwait_visas (created_at desc);
create index if not exists kuwait_visas_expiry_idx on public.kuwait_visas (expiry_date);

-- Keep updated_at honest without trusting the browser clock.
create or replace function public.kuwait_visas_touch()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists kuwait_visas_touch on public.kuwait_visas;
create trigger kuwait_visas_touch
  before update on public.kuwait_visas
  for each row execute function public.kuwait_visas_touch();

-- Row level security: enabled, with permissive demo policies.
alter table public.kuwait_visas enable row level security;

drop policy if exists "demo read visas" on public.kuwait_visas;
create policy "demo read visas"
  on public.kuwait_visas for select
  to anon, authenticated
  using (true);

drop policy if exists "demo insert visas" on public.kuwait_visas;
create policy "demo insert visas"
  on public.kuwait_visas for insert
  to anon, authenticated
  with check (true);

drop policy if exists "demo update visas" on public.kuwait_visas;
create policy "demo update visas"
  on public.kuwait_visas for update
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "demo delete visas" on public.kuwait_visas;
create policy "demo delete visas"
  on public.kuwait_visas for delete
  to anon, authenticated
  using (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.kuwait_visas to anon, authenticated;

-- ----------------------------------------------------------------------------
-- Optional sample row, so a fresh project shows something on the first check.
-- It is labelled as a placeholder on purpose; delete it or skip this block if
-- you would rather start with an empty register.
-- ----------------------------------------------------------------------------
insert into public.kuwait_visas (
  code, full_name_en, full_name_ar, passport_no,
  nationality_en, nationality_ar, gender, date_of_birth,
  profession_en, profession_ar, visa_type_en, visa_type_ar,
  issue_date, expiry_date, photo_url
) values (
  '123456',
  'SAMPLE APPLICANT NAME',
  'الاسم التجريبي لمقدم الطلب',
  'P0000000',
  'Ethiopian',
  'إثيوبي',
  'Male',
  date '1992-04-17',
  'Driver',
  'سائق',
  'Work visa, Article 18',
  'تأشيرة عمل، مادة 18',
  current_date - 6,
  current_date + 84,
  ''
)
on conflict (code) do nothing;
