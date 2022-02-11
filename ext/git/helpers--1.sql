-- creates git.pg_xxx views
do language plpgsql
$plpgsql$
  declare
    rec record;
  begin
    for rec in (
      select relname as name,
             array_agg(format(
               '%s%s as %s',
               case
                 -- TODO: Use PK cols instead of hardcoding values
                 when attname in ('oid', 'roident') then
                   format('(pg_identify_object(%L::regclass, %I, 0)).identity', relname, attname)
                 when attname in ('objoid') and relname like 'pg_sh%' then
                   format('classoid::regclass || $$ $$ || (pg_identify_object(classoid, objoid, 0)).identity')
                 when attname in ('objoid') then
                   format('classoid::regclass || $$ $$ || (pg_identify_object(classoid, objoid, objsubid)).identity')
                 when pktable::name = 'pg_attribute' and not is_array then
                   format('(pg_identify_object(%L::regclass, %I, %I)).identity', 'pg_class', fkcols[1], fkcols[2])
                 when pktable::name = 'pg_attribute' and is_array then
                   format('(select array_agg((pg_identify_object(%L::regclass, %I, attnum)).identity) from unnest(%I) as attnum)', 'pg_class', fkcols[1], fkcols[2])
                 when relname = 'pg_attribute' and attname='attrelid' then
                   format('(pg_identify_object(%L::regclass, attrelid, attnum)).identity', 'pg_class')
                 when not is_array then
                   format('(pg_identify_object(%L::regclass, %I, 0)).identity', pktable, fkcols[1])
                 when is_array then
                   format('(select array_agg((pg_identify_object(%L::regclass, oid, 0)).identity) from unnest(%I) as oid)', pktable, fkcols[1])
                 else attname::text
               end,
               case atttypid
                 -- roles don't exist on control cluster
                 when 'aclitem[]'::regtype then '::text[]'
                 -- can't be serialized through postgres_fdw
                 when 'pg_node_tree'::regtype then '::text'
                 else ''
               end,
               case attnum when 1 then 'uid' else attname end
             ) order by attnum) as cols
        from pg_class
             join pg_attribute
               on attrelid = oid
                  and attnum >= 0
                  and atttypid not in ('anyarray'::regtype)
             left join pg_get_catalog_foreign_keys()
                    on relname = fktable::name
                       and attname = fkcols[array_upper(fkcols, 1)]
       where relnamespace='pg_catalog'::regnamespace
             and relkind='r'
             and relname not in ('pg_depend', 'pg_shdepend', 'pg_statistic', 'pg_statistic_ext_data', 'pg_subscription_rel')
       group by relname
    ) loop
      execute format($format$
          create view @extschema@.%1$I as select
            %2$s
          from pg_catalog.%1$I;
        $format$, rec.name, array_to_string(rec.cols, E',\n'));
    end loop;
  end
$plpgsql$;
