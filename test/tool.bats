#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
PATH="./tools:$PATH"

@test "runs all helpers successfully in CI" {
  export PG_DEV_CI=1

  run -0 \
    tool \
    with menu \
    with watcher \
    with pg \
    with sql test/schema.sql \
    with async psql \
    with pg_prove test/passing.spec.sql

  run -1 \
    tool \
    with menu \
    with watcher \
    with pg \
    with sql test/schema.sql \
    with async psql \
    with pg_prove test/failing.spec.sql
}

@test "runs all helpers successfully without tool" {
  # except async and watcher, as we don't want to hang

  run -0 \
    with menu \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/passing.spec.sql

  run -1 \
    with menu \
    with pg \
    with sql test/schema.sql \
    with pg_prove test/failing.spec.sql
}
