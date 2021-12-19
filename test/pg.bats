#!/usr/bin/env bats
PATH="./tools:$PATH"

@test "with pg runs command with current user (root)" {
  skip
  : | run -0 tool with -q pg with whoami
  [ "$output" = "$(whoami)" ]
}

@test "with pg runs command with current user (other)" {
  skip
  adduser -S test || true
  : | run -0 su-exec test tool with -q pg with whoami
  [ "$output" = "test" ]
}
