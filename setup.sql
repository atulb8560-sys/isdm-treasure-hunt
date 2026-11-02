-- ISDM Treasure Hunt registration database
-- Run this entire script in Supabase Dashboard > SQL Editor.
create table if not exists public.treasure_hunt_participants (
  id bigint generated always as identity primary key,
  name text not null check (char_length(trim(name)) between 1 and 60),
  selected_team integer not null check (selected_team between 1 and 4),
  display_team integer not null default 1 check (display_team between 1 and 4),
  final_team integer check (final_team between 1 and 4),
  created_at timestamptz not null default now()
);

-- Prevent duplicate names, ignoring case and extra spaces.
create unique index if not exists treasure_hunt_unique_name
on public.treasure_hunt_participants (lower(trim(name)));

alter table public.treasure_hunt_participants enable row level security;

drop policy if exists "Anyone can view treasure hunt names" on public.treasure_hunt_participants;
create policy "Anyone can view treasure hunt names"
on public.treasure_hunt_participants for select to anon, authenticated using (true);

-- Do not allow direct public inserts/updates/deletes. Registration happens through the function.
revoke insert, update, delete on public.treasure_hunt_participants from anon, authenticated;
grant select on public.treasure_hunt_participants to anon, authenticated;
grant usage, select on sequence public.treasure_hunt_participants_id_seq to postgres;

create or replace function public.register_treasure_hunt_participant(
  p_name text,
  p_selected_team integer
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id bigint;
  clean_name text := trim(p_name);
  cutoff timestamptz := '2026-11-04 23:59:00+05:30';
begin
  if now() >= cutoff then
    raise exception 'Registration is closed.';
  end if;
  if clean_name is null or char_length(clean_name) < 1 or char_length(clean_name) > 60 then
    raise exception 'Please enter a name between 1 and 60 characters.';
  end if;
  if p_selected_team not between 1 and 4 then
    raise exception 'Please select one of the four teams.';
  end if;

  insert into public.treasure_hunt_participants(name, selected_team)
  values (clean_name, p_selected_team)
  returning id into new_id;

  -- Randomly reshuffle all participants and distribute them as evenly as possible.
  with randomized as (
    select id, ((row_number() over (order by random()) - 1) % 4 + 1)::integer as team_no
    from public.treasure_hunt_participants
    where final_team is null
  )
  update public.treasure_hunt_participants p
  set display_team = randomized.team_no
  from randomized
  where p.id = randomized.id;

  return json_build_object('id', new_id, 'message', 'Registration successful');
exception
  when unique_violation then
    raise exception 'This name is already registered. Please check the spelling or contact the organiser.';
end;
$$;

revoke all on function public.register_treasure_hunt_participant(text, integer) from public;
grant execute on function public.register_treasure_hunt_participant(text, integer) to anon, authenticated;

-- Enable realtime updates for this table (ignore the message if it is already in the publication).
do $$
begin
  alter publication supabase_realtime add table public.treasure_hunt_participants;
exception when duplicate_object then null;
when undefined_object then
  raise notice 'Create/enable the supabase_realtime publication in Database > Publications, then add treasure_hunt_participants.';
end $$;
