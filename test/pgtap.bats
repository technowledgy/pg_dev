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

@test "runs pg_prove successfully with tool --ci and helpers" {
  run -0 \
    tool --ci \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/passing.spec.sql

  run -1 \
    tool --ci \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/failing.spec.sql
}
