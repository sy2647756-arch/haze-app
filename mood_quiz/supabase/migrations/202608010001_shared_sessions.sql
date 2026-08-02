create extension if not exists pgcrypto;

create table if not exists public.haze_shared_sessions (
  id uuid primary key default gen_random_uuid(),
  token text not null unique default encode(gen_random_bytes(24), 'hex'),
  kind text not null check (kind in ('coop_quiz', 'what_if')),
  context_id text not null,
  initiator_name text,
  initiator_payload jsonb not null default '{}'::jsonb,
  guest_name text,
  guest_payload jsonb,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);

alter table public.haze_shared_sessions enable row level security;
revoke all on public.haze_shared_sessions from anon, authenticated;

create or replace function public.haze_create_shared_session(
  p_kind text,
  p_context_id text,
  p_initiator_name text,
  p_initiator_payload jsonb
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_token text;
begin
  insert into public.haze_shared_sessions(
    kind, context_id, initiator_name, initiator_payload
  ) values (
    p_kind, p_context_id, nullif(trim(p_initiator_name), ''), p_initiator_payload
  ) returning token into v_token;
  return v_token;
end;
$$;

create or replace function public.haze_get_shared_session(p_token text)
returns table (
  token text,
  kind text,
  context_id text,
  initiator_name text,
  initiator_payload jsonb,
  guest_name text,
  guest_payload jsonb,
  completed_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select s.token, s.kind, s.context_id, s.initiator_name,
         s.initiator_payload, s.guest_name, s.guest_payload, s.completed_at
  from public.haze_shared_sessions s
  where s.token = p_token and s.expires_at > now()
  limit 1;
$$;

create or replace function public.haze_complete_shared_session(
  p_token text,
  p_guest_name text,
  p_guest_payload jsonb
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.haze_shared_sessions
  set guest_name = nullif(trim(p_guest_name), ''),
      guest_payload = p_guest_payload,
      completed_at = now()
  where token = p_token and expires_at > now();
  return found;
end;
$$;

revoke all on function public.haze_create_shared_session(text, text, text, jsonb) from public;
revoke all on function public.haze_get_shared_session(text) from public;
revoke all on function public.haze_complete_shared_session(text, text, jsonb) from public;
grant execute on function public.haze_create_shared_session(text, text, text, jsonb) to anon, authenticated;
grant execute on function public.haze_get_shared_session(text) to anon, authenticated;
grant execute on function public.haze_complete_shared_session(text, text, jsonb) to anon, authenticated;
