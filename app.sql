
-- ROLES

create role authenticator noinherit login;

comment on role authenticator is
  'Role that PostgREST will log in as initially.';

create role anonymous noinherit nologin;

comment on role anonymous is
  'The role that PostgREST will switch to for unauthenticated users.';

create role api noinherit nologin;

comment on role api is
  'Role with limted privileges that owns the API schema and its objects.';


-- SCHEMAS

create schema app;

comment on schema app is
  'Schema that contains the state and business logic of our application.';

grant usage on schema app to api;

create schema authorization api;

comment on schema api is
  'Schema owned by the api role that describes the API of our application.';

grant usage on schema api to anonymous;


-- APPLICATION

create table app.todos
  ( todo_id serial primary key
  , description text not null
  , created timestamptz not null default clock_timestamp()
  , done bool not null default false
  );

grant
  select,
  insert(description),
  update(description, done),
  delete
on table app.todos
to api;

grant all on app.todos_todo_id_seq to anonymous;

create view api.todos as
  select
    todo_id,
    description,
    created,
    done
  from app.todos;

grant select on api.todos to anonymous;
