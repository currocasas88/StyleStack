-- StyleStack — Supabase Schema
-- Paste into Supabase SQL editor and run.
-- RLS enabled on all tables. Users can only access their own data.

create extension if not exists "uuid-ossp";

-- ── user_profiles (extends Supabase auth.users) ───────────────────────────────
create table public.user_profiles (
  id           uuid references auth.users on delete cascade primary key,
  preferences  jsonb not null default '{"units":"metric"}',
  created_at   timestamptz not null default now()
);
alter table public.user_profiles enable row level security;
create policy "own profile only"
  on public.user_profiles for all using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── garments ──────────────────────────────────────────────────────────────────
create table public.garments (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid references auth.users on delete cascade not null,
  image_path     text not null,
  category       text,
  colors         text[] not null default '{}',
  brand          text,
  tags           text[] not null default '{}',
  season         text[] not null default '{}',
  user_category  text,
  user_tags      text[] not null default '{}',
  user_notes     text,
  times_worn     integer not null default 0,
  last_worn_at   timestamptz,
  is_archived    boolean not null default false,
  created_at     timestamptz not null default now()
);
alter table public.garments enable row level security;
create policy "own garments only"
  on public.garments for all using (auth.uid() = user_id);
create index garments_user_idx      on public.garments(user_id);
create index garments_category_idx  on public.garments(user_id, category) where not is_archived;

-- ── outfits ───────────────────────────────────────────────────────────────────
create table public.outfits (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid references auth.users on delete cascade not null,
  garment_ids     uuid[] not null,
  source          text not null check (source in ('ai', 'user')),
  occasion        text,
  weather_context jsonb,
  rating          smallint check (rating between 1 and 5),
  worn_at         timestamptz,
  is_saved        boolean not null default false,
  created_at      timestamptz not null default now()
);
alter table public.outfits enable row level security;
create policy "own outfits only"
  on public.outfits for all using (auth.uid() = user_id);
create index outfits_user_idx   on public.outfits(user_id);
create index outfits_saved_idx  on public.outfits(user_id, is_saved) where is_saved;

-- ── upload_jobs ───────────────────────────────────────────────────────────────
create table public.upload_jobs (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid references auth.users on delete cascade not null,
  garment_ids  uuid[] not null default '{}',
  total        integer not null,
  processed    integer not null default 0,
  status       text not null default 'pending'
                 check (status in ('pending', 'processing', 'done', 'failed')),
  error        text,
  created_at   timestamptz not null default now()
);
alter table public.upload_jobs enable row level security;
create policy "own upload jobs only"
  on public.upload_jobs for all using (auth.uid() = user_id);

-- ── Storage ───────────────────────────────────────────────────────────────────
-- Create in Supabase dashboard: Storage > New bucket
-- Name: garments  |  Private: YES  |  No public access
-- 
-- RLS policy for storage (run in SQL editor):
-- create policy "users can manage own garment images"
--   on storage.objects for all
--   using (auth.uid()::text = (storage.foldername(name))[1])
--   with check (auth.uid()::text = (storage.foldername(name))[1]);
--
-- File path convention: {user_id}/{garment_id}.jpg
