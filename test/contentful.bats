#!/usr/bin/env bats

load 'test_helper/utils'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/mocks/stub'

setup() {
  stub_node_deps
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