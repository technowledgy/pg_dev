#!/usr/bin/env bats

@test "with_pg runs command with current user (root)" {
  run -0 tools/with_pg whoami
  [ "$output" = "$(whoami)" ]
}

@test "with_pg runs command with current user (other)" {
  adduser -S test || true
  run -0 su-exec test tools/with_pg whoami
  [ "$output" = "test" ]
}
