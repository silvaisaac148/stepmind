-- StepMind: esquema inicial para sincronizar los datos del teléfono.
-- Ejecutar en Supabase → SQL Editor (o con `supabase db push`).
--
-- Cada fila pertenece a un usuario (user_id) y RLS garantiza que nadie
-- pueda leer ni escribir datos de otro. Las fechas de la app viajan como
-- milisegundos (bigint); synced_at lo pone el servidor y sirve de cursor
-- para bajar solo lo que cambió.

create table public.habits (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  name text not null check (char_length(name) between 1 and 200),
  reminder_minutes integer not null check (reminder_minutes between 0 and 1439),
  created_at bigint not null,
  archived_at bigint,
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp(),
  primary key (user_id, id)
);

create table public.checkins (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  habit_id text not null,
  day text not null check (day ~ '^\d{4}-\d{2}-\d{2}$'),
  created_at bigint not null,
  deleted boolean not null default false,
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp(),
  primary key (user_id, habit_id, day)
);

create table public.events (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  day text not null check (day ~ '^\d{4}-\d{2}-\d{2}$'),
  title text not null check (char_length(title) <= 500),
  deleted boolean not null default false,
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp(),
  primary key (user_id, id)
);

create table public.profiles (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  username text not null default '',
  age integer not null default 0,
  country text not null default '',
  updated_at bigint not null,
  synced_at timestamptz not null default clock_timestamp()
);

create index habits_user_synced_idx on public.habits (user_id, synced_at);
create index checkins_user_synced_idx on public.checkins (user_id, synced_at);
create index events_user_synced_idx on public.events (user_id, synced_at);

-- synced_at siempre lo pone el servidor. Si llega un cambio más viejo que el
-- guardado (otro teléfono ya subió uno más reciente), se ignora.
create function public.stepmind_touch_synced_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return old;
  end if;
  new.synced_at := clock_timestamp();
  return new;
end;
$$;

create trigger habits_touch before insert or update on public.habits
  for each row execute function public.stepmind_touch_synced_at();
create trigger checkins_touch before insert or update on public.checkins
  for each row execute function public.stepmind_touch_synced_at();
create trigger events_touch before insert or update on public.events
  for each row execute function public.stepmind_touch_synced_at();
create trigger profiles_touch before insert or update on public.profiles
  for each row execute function public.stepmind_touch_synced_at();

-- Seguridad: cada usuario solo ve y modifica sus filas.
alter table public.habits enable row level security;
alter table public.checkins enable row level security;
alter table public.events enable row level security;
alter table public.profiles enable row level security;

create policy "habits: dueño" on public.habits for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "checkins: dueño" on public.checkins for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "events: dueño" on public.events for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "profiles: dueño" on public.profiles for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Los anónimos no tienen ningún acceso.
revoke all on public.habits, public.checkins, public.events, public.profiles from anon;
