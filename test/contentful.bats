#!/usr/bin/env bats

log() {
  >&3 echo "$@" || true
}

logerr() {
  >&3 echo -e "${COLOR_RED}$@${COLOR_NC}"
}

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# setup() {
# }

# teardown() {
# }

@test "prints help" {
  run bin/contentful -h
  assert_success
  assert_output --partial "bin/contentful <command> [opts]"
}