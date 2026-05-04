-- ============================================
-- Workspace App — Supabase Schema
-- Run this in Supabase > SQL Editor > New Query
-- ============================================

-- Groups table
create table if not exists groups (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  color text not null default '#3D4F2E',
  sort_order int default 0,
  created_at timestamptz default now()
);

-- Tasks table
create table if not exists tasks (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  gid text references groups(id) on delete cascade not null,
  name text not null,
  type text not null check (type in ('task','recurring','list')),
  done boolean default false,
  streak int default 0,
  freq text check (freq in ('daily','weekly') or freq is null),
  priority text check (priority in ('p1','p2','p3') or priority is null),
  due_date text default '',
  note text default '',
  subtasks jsonb default '[]',
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Row Level Security: users only see their own data
alter table groups enable row level security;
alter table tasks enable row level security;

create policy "Users manage own groups"
  on groups for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own tasks"
  on tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-update updated_at on task changes
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger tasks_updated_at
  before update on tasks
  for each row execute function update_updated_at();
