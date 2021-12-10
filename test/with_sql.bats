#!/usr/bin/env bats
load "$(yarn global dir)/node_modules/bats-support/load.bash"
load "$(yarn global dir)/node_modules/bats-assert/load.bash"

export TERM=vt100

@test "with_sql adds multiple menu items when called multiple times" {
  run -0 \
    tools/with_menu \
    tools/with_pg \
    tools/with_sql test/schema.sql \
    tools/with_sql test/schema.spec.sql \
    echo test \
    <<< 'q'
  assert_line --regexp 'show output for with_sql test/schema.sql'
  assert_line --regexp 'show output for with_sql test/schema.spec.sql'
}
