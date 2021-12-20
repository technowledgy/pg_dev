#!/usr/bin/env bats
load "$(yarn global dir)/node_modules/bats-support/load.bash"
load "$(yarn global dir)/node_modules/bats-assert/load.bash"

PATH="./tools:$PATH"

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
