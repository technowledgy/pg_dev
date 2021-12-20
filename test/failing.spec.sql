BEGIN;
SELECT plan(1);

SELECT has_table('f');

SELECT * FROM finish();
ROLLBACK;
