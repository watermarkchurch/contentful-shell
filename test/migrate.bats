#!/usr/bin/env bats

load 'test_helper/utils'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'test_helper/mocks/stub'

ROOT=`pwd`
DIR="$ROOT/test"
FIXTURES="$DIR/fixtures"

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

@test 'runs contentful-migration with provided env vars' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace -a mgmttoken -p db/migrate : false" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmttoken run $ROOT/bin/contentful -v migrate

  assert_failure  

  unstub ts-node
}

@test 'does not run comparison if migration fails' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace -a mgmt-token -p db/migrate : false" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmt-token run $ROOT/bin/contentful -v migrate

  assert_failure
  assert_file_not_exist db/contentful-schema.json
  refute_output --partial contentful-export

  unstub ts-node
}

@test 'uses flags to override environment variables' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace2 --environment-id testenv -a mgmt-token-2 -p batch migration_folder : false" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node
  mkdir -p migration_folder

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmt-token \
    run $ROOT/bin/contentful -v migrate -s testspace2 -a mgmt-token-2 -e testenv migration_folder

  assert_failure
  refute_output --partial contentful-export

  unstub ts-node
}

@test 'exports schema after successful migration' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace -a mgmt-token -p batch db/migrate : true" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node
  stub contentful-export \
    "--export-dir db --content-file contentful-schema.tmp.json --space-id testspace --management-token mgmt-token --skip-content : cp $FIXTURES/contentful-schema.tmp.json db/"
  ln -f -s ${BATS_MOCK_BINDIR}/contentful-export node_modules/.bin/contentful-export
  stub curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmt-token : echo '{ \"name\": \"Test Space\" }'"

  mkdir -p db/migrate

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmt-token \
    run $ROOT/bin/contentful -v migrate

  assert_success
  assert_file_exist db/contentful-schema.json
  assert_output --partial "Schema in test space/master differs from stored schema"

  unstub ts-node
  unstub contentful-export
}

@test 'prints success message if exported schema equivalent to expected schema' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace -a mgmt-token -p batch db/migrate : true" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node
  stub contentful-export \
    "--export-dir db --content-file contentful-schema.tmp.json --space-id testspace --management-token mgmt-token --skip-content : cp $FIXTURES/contentful-schema.tmp.json db/"
  ln -f -s ${BATS_MOCK_BINDIR}/contentful-export node_modules/.bin/contentful-export
  stub curl \
    "-s https://api.contentful.com/spaces/testspace?access_token=mgmt-token : echo '{ \"name\": \"Test Space\" }'"

  mkdir -p db/migrate
  cp $FIXTURES/contentful-schema.json db/

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmt-token \
    run $ROOT/bin/contentful -v migrate

  assert_success
  assert_file_exist db/contentful-schema.json
  assert_output --partial "Schema in test space/master is equivalent to stored schema"

  unstub ts-node
  unstub contentful-export
}