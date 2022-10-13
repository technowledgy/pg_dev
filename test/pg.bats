#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
load "$(yarn global dir)/node_modules/bats-support/load.bash"
load "$(yarn global dir)/node_modules/bats-assert/load.bash"

PATH="./tools:$PATH"

function teardown() {
  rm -f /var/run/postgresql/*
}

@test "with pg runs command with current user (root)" {
  run -0 \
    with pg \
    with sh -c 'echo -n =====WHOAMI=====; whoami'
  assert_output --partial "=====WHOAMI=====$(whoami)"
}

@test "with pg runs command with current user (other)" {
  adduser -S test || true
  run -0 \
    su-exec test \
    with pg \
    with sh -c 'echo -n =====WHOAMI=====; whoami'
  assert_output --partial "=====WHOAMI=====test"
}

@test "with pg runs command with current user (without passwd entry)" {
  run -0 \
    su-exec 1234:1235 \
    with pg \
    with sh -c 'echo -n =====WHOAMI=====; id'
  assert_output --partial "=====WHOAMI=====uid=1234 gid=1235 groups=1235"
}

@test "with pg uses standard port" {
  run -0 \
    with pg
  assert_output --partial 'listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"'
}

@test "with pg uses next available port" {
  touch /var/run/postgresql/.s.PGSQL.5432
  touch /var/run/postgresql/.s.PGSQL.5433
  touch /var/run/postgresql/.s.PGSQL.5435
  run -0 \
    with pg
  assert_output --partial 'listening on Unix socket "/var/run/postgresql/.s.PGSQL.5434"'
}

@test "with pg uses given port" {
  PGPORT=5555 \
  run -0 \
    with pg
  assert_output --partial 'listening on Unix socket "/var/run/postgresql/.s.PGSQL.5555"'
}

@test "with pg waits for availability of given port" {
  touch /var/run/postgresql/.s.PGSQL.5555
  sh -c 'sleep 1; rm /var/run/postgresql/.s.PGSQL.5555' &
  assert [ -e /var/run/postgresql/.s.PGSQL.5555 ]
  PGPORT=5555 \
  run -0 \
    with pg
  assert_output --partial 'listening on Unix socket "/var/run/postgresql/.s.PGSQL.5555"'
}
