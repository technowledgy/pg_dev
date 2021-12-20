BEGIN;
SELECT plan(1);

SELECT has_table('t');

SELECT * FROM finish();
ROLLBACK;
