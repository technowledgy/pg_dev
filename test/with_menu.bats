#!/usr/bin/env bats
load "$(yarn global dir)/node_modules/bats-support/load.bash"
load "$(yarn global dir)/node_modules/bats-assert/load.bash"

@test "with_menu runs command" {
  run -0 --separate-stderr \
    tools/with_menu echo test \
    <<< 'q'
  assert_output 'test'
}

@test "with_menu runs command again with ENTER" {
  run -0 --separate-stderr \
    tools/with_menu echo test \
    <<< $'\nq'
  assert_output $'test\ntest'
}

@test "with_menu acts on items added with _with_menu_item" {
  run -0 --separate-stderr \
    tools/with_menu tools/_with_menu_item t "run echo" echo test \
    <<< $'t\nt\nq'
  assert_output $'test\ntest'
}

@test "with_menu displays menu on stderr" {
  run -0 \
    tools/with_menu tools/_with_menu_item t "run echo" echo test \
    <<< 'q'
  output="$(echo "$output" | tr -d '\e')"
  assert_output '[?12l[?25h[H[2J[3J[?25l
[K[0;37mCommand Usage[0m
[K[0;37m › Press [1;97mENTER[0;37m to re-run command.[0m
[K[0;37m › Press [1;97mt[0;37m to run echo.[0m
[K[0;37m › Press [1;97m0[0;37m to show output for final command.[0m
[K[0;37m › Press [1;97mq[0;37m to quit.[0m
[4A[2A[K[?12l[?25h'
}
