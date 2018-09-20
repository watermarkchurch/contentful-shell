#!/usr/bin/env bats

COLOR_NC='\033[0m' # No Color
COLOR_GRAY='\033[1;30m'
COLOR_RED='\033[0;31m'
COLOR_LCYAN='\033[1;36m'
COLOR_YELLOW='\033[1;33m'
COLOR_LGREEN='\033[1;32m'

log() {
  >&3 echo "$@" || true
}

logerr() {
  >&3 echo -e "${COLOR_RED}$@${COLOR_NC}"
}

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/mocks/stub'

setup() {
  mkdir -p node_modules/.bin/
  touch node_modules/.bin/contentful-migration
  touch node_modules/.bin/ts-node
  touch node_modules/.bin/contentful-export
  touch node_modules/.bin/contentful-import
}

# teardown() {
# }

@test "prints help" {
  run bin/contentful -h
  assert_success
  assert_output --partial "bin/contentful <command> [opts]"
}

@test "does not allow unknown subcommand" {
  run bin/contentful asdfblah
  assert_failure
  assert_output --partial "asdfblah"
}

@test "allows flags before and after subcommand" {
  stub curl \
    "-s https://api.contentful.com/spaces/testspace/environments?access_token=test-token : cat test/fixtures/environments.json"

  run bin/contentful -s testspace env -a test-token -e test

  assert_success
  assert_output <<- EOF
Environments:
  master
  gburgett
  staging
EOF

  unstub curl
}