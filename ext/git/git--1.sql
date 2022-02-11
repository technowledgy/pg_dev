create procedure create_server(name text, port int)
  language plpgsql as
$plpgsql$
  declare
    stmt text;
  begin
    execute format($format$
        create schema %1$I;
        create server %1$I
          foreign data wrapper postgres_fdw
          options (port %2$L);
        create user mapping for public
          server %1$I
          options (user 'postgres');
        import foreign schema @extschema@
          from server %1$I
          into %1$I;
      $format$, name, port);
  end
$plpgsql$;

call create_server('remote', 5433);
call create_server('local', 5434);

create function status(catalog text)
  returns setof text
  language plpgsql as
$plpgsql$
  begin
    return query execute format($format$
        select '# %1$s';
        select format('%%s %%s %%s %%s',
                 case
                   when remote.uid is null and local.uid is not null then 'A'
                   when local.uid is null and remote.uid is not null then 'D'
                   else 'M'
                 end,
                 uid,
                 remote,
                 local
               )
          from remote.%1$I as remote
          full join
               local.%1$I as local
               using (uid)
         where remote is distinct from local;
        select '';
      $format$, catalog);
  end
$plpgsql$;
