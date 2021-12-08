#!/usr/bin/env bats

@test "with_tmp_db runs command with current user (root)" {
  run -0 with_tmp_db whoami
  [ "$output" = "$(whoami)" ]
}

@test "with_tmp_db runs command with current user (other)" {
  adduser -S test
  run -0 su-exec test with_tmp_db whoami
  [ "$output" = "test" ]
}
