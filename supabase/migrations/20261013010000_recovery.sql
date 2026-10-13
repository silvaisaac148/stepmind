-- StepMind: módulo de adicciones (solo se usa si el usuario activa
-- "Sincronizar datos de adicciones" en Ajustes; por defecto no sale del teléfono).
-- Ejecutar en Supabase → SQL Editor.

create table public.recovery_goals (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  name text not null check (char_length(name) between 1 and 100),
  started_at bigint not null,
  why text not null default '' check (char_length(why) <= 4000),
  plans_json text not null default '[]' check (char_length(plans_json) <= 20000),
  created_at bigint not null,
  archived_at bigint,
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp(),
  primary key (user_id, id)
);

create table public.recovery_events (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  goal_id text not null,
  kind text not null check (kind in ('slip', 'urge')),
  at bigint not null,
  emotion text check (char_length(emotion) <= 100),
  situation text check (char_length(situation) <= 200),
  intensity integer check (intensity between 1 and 10),
  resisted boolean not null default false,
  note text check (char_length(note) <= 4000),
  deleted boolean not null default false,
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp(),
  primary key (user_id, id)
);

create index recovery_goals_user_synced_idx on public.recovery_goals (user_id, synced_at);
create index recovery_events_user_synced_idx on public.recovery_events (user_id, synced_at);

create trigger recovery_goals_touch before insert or update on public.recovery_goals
  for each row execute function public.stepmind_touch_synced_at();
create trigger recovery_events_touch before insert or update on public.recovery_events
  for each row execute function public.stepmind_touch_synced_at();

alter table public.recovery_goals enable row level security;
alter table public.recovery_events enable row level security;

create policy "recovery_goals: dueño" on public.recovery_goals for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "recovery_events: dueño" on public.recovery_events for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

revoke all on public.recovery_goals, public.recovery_events from anon;
