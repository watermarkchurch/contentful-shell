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

export CONTENTFUL_SPACE_ID=testspace
export CONTENTFUL_MANAGEMENT_TOKEN=mgmttoken
export CONTENTFUL_ACCESS_TOKEN=testtoken

setup() {
  [[ ! -f "$BATS_MOCK_TMPDIR" ]] || rm -rf "$BATS_MOCK_TMPDIR"
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  stub_node_deps
}

teardown() {
  popd
}

@test 'creates a new environment' {
  stub stubbed-curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmttoken : cat $FIXTURES/space.json" \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmttoken : cat $FIXTURES/space.json" \
    "-s -o /dev/null -w %{http_code} https://api.contentful.com/spaces/testspace/environments/testenv?access_token=mgmttoken : echo 404" \
    "-s --fail -XPUT https://api.contentful.com/spaces/testspace/environments/testenv -H Authorization: Bearer mgmttoken -H Content-Type: application/vnd.contentful.management.v1+json -d { \"name\": \"testenv\" } : true" \
    "-s --fail https://api.contentful.com/spaces/testspace/api_keys?access_token=mgmttoken : cat $FIXTURES/api_keys.json" \
    '-s -o /dev/null --fail -XPUT https://api.contentful.com/spaces/testspace/api_keys/3U5300um9CPAafmmnoKRuc -H Authorization: Bearer mgmttoken -H Content-Type: application/vnd.contentful.management.v1+json -H X-Contentful-Version: 21 -d {"environments":[{"sys":{"id":"master","type":"Link","linkType":"Environment"}},{"sys":{"id":"testenv","type":"Link","linkType":"Environment"}}]} : true'

  # act
  run $ROOT/bin/contentful -v new_env -e testenv -y

  unstub stubbed-curl
  assert_success
  assert_output --partial "Environment testenv successfully created!"
}
