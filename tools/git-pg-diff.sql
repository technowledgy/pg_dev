\set QUIET on
\t on
\pset pager 0

create extension postgres_fdw;
create extension git;

select git.status(relname)
  from pg_class
 where relkind='f'
       and relnamespace = 'local'::regnamespace
       -- TODO: array fks need to be joined to base tables as arrays
       and relname not in ('pg_ts_config_map')
 order by relname;
