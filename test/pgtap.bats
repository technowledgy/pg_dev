#!/usr/bin/env bats

@test "runs pg_prove successfully with helpers" {
  run -0 tools/with_pg tools/with_sql test/schema.sql pg_prove test/schema.spec.sql
}
