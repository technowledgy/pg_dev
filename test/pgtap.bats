#!/usr/bin/env bats
PATH="./tools:$PATH"

@test "runs pg_prove successfully with helpers" {
  skip
  : | run -0 pg sql test/schema.sql pg_prove test/schema.spec.sql
}
