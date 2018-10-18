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

@test 'success if env doesnt exist' {
  stub stubbed-curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmttoken : cat $FIXTURES/space.json" \
    "-s -o /dev/null -w %{http_code} https://api.contentful.com/spaces/testspace/environments/testenv?access_token=mgmttoken : echo '404'"

  # act
  run $ROOT/bin/contentful -v wipe -e testenv -y

  unstub stubbed-curl
  assert_success
  assert_output --partial "testenv does not exist in wmr.com"
}

@test 'success if no entries or assets' {
  stub date \
    '+%Y-%m-%dT%H-%M-%S : echo "2018-01-01"'

  stub stubbed-curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmttoken : cat $FIXTURES/space.json" \
    "-s -o /dev/null -w %{http_code} https://api.contentful.com/spaces/testspace/environments/testenv?access_token=mgmttoken : echo '200'"

  stub contentful-export \
    "--content-file contentful-export-testspace-testenv-2018-01-01.json --space-id testspace --environment-id=testenv --management-token mgmttoken --include-drafts : cp $FIXTURES/contentful-export-empty.json contentful-export-testspace-testenv-2018-01-01.json"
  ln -f -s ${BATS_MOCK_BINDIR}/contentful-export node_modules/.bin/contentful-export

  # act
  run $ROOT/bin/contentful -v wipe -e testenv -y

  unstub stubbed-curl
  unstub date
  unstub contentful-export
  assert_success
  assert_output --partial "wipe complete!"
}

@test 'wipes all entries and content types' {
  stub date \
    '+%Y-%m-%dT%H-%M-%S : echo "2018-01-01"'

  stub contentful-export \
    "--content-file contentful-export-testspace-testenv-2018-01-01.json --space-id testspace --environment-id=testenv --management-token mgmttoken --include-drafts : cp $FIXTURES/contentful-export-for-wipe.json contentful-export-testspace-testenv-2018-01-01.json"
  ln -f -s ${BATS_MOCK_BINDIR}/contentful-export node_modules/.bin/contentful-export

  stub stubbed-curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmttoken : cat $FIXTURES/space.json" \
    "-s -o /dev/null -w %{http_code} https://api.contentful.com/spaces/testspace/environments/testenv?access_token=mgmttoken : echo '200'" \
    "-XDELETE -s -o /dev/null -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/entries/Wa6UANVREQGqgWSc826ae/published : true" \
    "--fail -s -o /dev/null -XDELETE -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/entries/Wa6UANVREQGqgWSc826ae : true" \
    "-XDELETE -s -o /dev/null -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/entries/2L71nVWkta04iSGOSgWQwW/published : true" \
    "--fail -s -o /dev/null -XDELETE -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/entries/2L71nVWkta04iSGOSgWQwW : true" \
    "-XDELETE -s -o /dev/null -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/content_types/testimonial/published : true" \
    "--fail -s -o /dev/null -XDELETE -H Authorization: Bearer mgmttoken https://api.contentful.com/spaces/testspace/environments/testenv/content_types/testimonial : true"

  # act
  run $ROOT/bin/contentful -v wipe -e testenv -y

  unstub stubbed-curl
  unstub date
  unstub contentful-export
  assert_success
  assert_output --partial "2 entries"
  assert_output --partial "1 content types"
  assert_output --partial "wipe complete!"
}