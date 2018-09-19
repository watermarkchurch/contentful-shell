#!/usr/bin/env bats

log() {
  >&3 echo "$@" || true
}

logerr() {
  >&3 echo -e "${COLOR_RED}$@${COLOR_NC}"
}

# setup() {
# }

# teardown() {
# }

@test "prints help" {
  run bin/contentful -h
  [ "$status" -eq 0 ]
  [ "${lines[0]}" =  "bin/contentful <command> [opts]" ]
}