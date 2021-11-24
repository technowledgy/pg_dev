BEGIN;
SELECT plan(1);

SELECT has_table('t');

select f1();

SELECT * FROM finish();
ROLLBACK;
