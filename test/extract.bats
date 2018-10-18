#!/usr/bin/env bats

load 'test_helper/utils'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'test_helper/mocks/stub'

ROOT=`pwd`
DIR="$ROOT/test"
FIXTURES="$DIR/fixtures"
export PATH="$DIR/stubs":$PATH

setup() {
  [[ ! -f "$BATS_MOCK_TMPDIR" ]] || rm -rf "$BATS_MOCK_TMPDIR"
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  stub_node_deps

  export CONTENTFUL_MANAGEMENT_TOKEN='mgmt-token'
  export CONTENTFUL_ACCESS_TOKEN='access-token'
  export CONTENTFUL_SPACE_ID='testspace'
}

teardown() {
  popd
}

mgmt_curl_stub="-s -H Content-Type: application/vnd.contentful.management.v1+json -H Authorization: Bearer mgmt-token https://api.contentful.com/spaces/testspace"

@test 'errors when no ID given' {
  run $ROOT/bin/contentful extract

  assert_failure
  assert_output --partial "No ID provided"
}

@test 'calls curl with default depth' {
  stub stubbed-curl \
    '-s -H Authorization: Bearer access-token --fail https://cdn.contentful.com/spaces/testspace/entries?sys.id=1234&locale=* : bash -c "exit 22"'

  run $ROOT/bin/contentful -v extract 1234

  log "$output"

  assert_failure
  unstub stubbed-curl

  # expect no output file written
  [[ -z "$(ls | grep contentful-)" ]]
}

@test 'sets appropriate depth on query' {
  stub stubbed-curl \
    '-s -H Authorization: Bearer access-token --fail https://cdn.contentful.com/spaces/testspace/entries?sys.id=1234&locale=*&include=4 : bash -c "exit 22"'

  run $ROOT/bin/contentful -v extract 1234 4

  log "$output"

  unstub stubbed-curl
}

# TODO: bats-mock has a problem with the square brackets in the arguments.
# If you throw a few `>&3 echo "pattern: $pattern"` statements inside mocks/binstub line 64,
# you'll see this:
# pattern : 'https://api.contentful.com/spaces/testspace/entries?sys.id[in]'
# argument: 'https://api.contentful.com/spaces/testspace/entries?sys.id[in]'
# result  : 1

# @test 'gets all included entries' {
#   stub stubbed-curl \
#     "-s -H Authorization: Bearer access-token --fail https://cdn.contentful.com/spaces/testspace/entries?sys.id=1234&locale=* : cat $FIXTURES/extract-include-2.json"
#   stub stubbed-curl \
#     "-s -H Content-Type: application/vnd.contentful.management.v1+json -H Authorization: Bearer mgmt-token https://api.contentful.com/spaces/testspace/entries?sys.id[in] : cat $FIXTURES/extract-entries-in.json"
#   >&3 cat ${BATS_MOCK_TMPDIR}/stubbed-curl-stub-plan
#   # stub stubbed-curl \
#   #   "$mgmt_curl_stub/assets?sys.id\[in\]=2rakCOkeRumQuig0K8uaYm : cat $FIXTURES/extract-assets-in.json"

#   run $ROOT/bin/contentful -v extract 1234

#   log "$output"

#   unstub stubbed-curl
# }

# @test 'gets all included assets' {
#   [[ 1 -eq 0 ]]
# }