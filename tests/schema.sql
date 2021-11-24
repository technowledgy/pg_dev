CREATE TABLE t ();

-- taken from plpgsql_check
CREATE OR REPLACE FUNCTION public.f1()
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM t
  LOOP
    RAISE NOTICE '%', r.c; -- there is bug - table t missing "c" column
  END LOOP;
END;
$function$;
