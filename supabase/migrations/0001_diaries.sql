-- Mood Quiz / Haze — 后端 v1
-- 0001: diaries 表（日记上云）。见 v1_设计决策记录.md §9。
-- 在 Supabase 控制台 SQL Editor 里整段执行一次即可。

create table if not exists public.diaries (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  date          date not null,
  weather       text not null check (weather in
                  ('stormy','rainy','gloomy','hazy','breezy','sunny','bright')),
  mood_score    int  not null check (mood_score between 1 and 7),
  content       text not null default '',
  image_urls    jsonb not null default '[]'::jsonb,   -- 媒体（第 5 步用）
  location_name text,                                 -- 地点（将来）
  latitude      float8,
  longitude     float8,
  is_backfilled boolean not null default false,
  created_at    timestamptz not null default now(),
  unique (user_id, date)                              -- 一天一篇
);

-- 行级安全：每人只能读写自己的日记。
alter table public.diaries enable row level security;

drop policy if exists "diaries are private to owner" on public.diaries;
create policy "diaries are private to owner"
  on public.diaries
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
