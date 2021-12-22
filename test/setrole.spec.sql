BEGIN;
SELECT plan(1);

CREATE ROLE test;

SET ROLE test;

SELECT has_table('t');

SELECT * FROM finish();
ROLLBACK;
