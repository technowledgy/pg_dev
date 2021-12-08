#!/usr/bin/env bats

@test "runs pg_prove successfully with helpers" {
  run -0 with_tmp_db with_sql test/schema.sql pg_prove test/schema.spec.sql
}
