#!/usr/bin/env bats

@test "with_pg runs command with current user (root)" {
  run -0 with_pg whoami
  [ "$output" = "$(whoami)" ]
}

@test "with_pg runs command with current user (other)" {
  adduser -S test
  run -0 su-exec test with_pg whoami
  [ "$output" = "test" ]
}
