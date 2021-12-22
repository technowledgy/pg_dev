#!/usr/bin/env bats
PATH="./tools:$PATH"

@test "runs pg_prove successfully with helpers" {
  run -0 \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/passing.spec.sql

  run -1 \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/failing.spec.sql
}

@test "pgtap is accessible by all users" {
  run -0 \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/setrole.spec.sql
}
