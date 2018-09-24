#!/usr/bin/env bats

load 'test_helper/utils'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'test_helper/mocks/stub'

DIR=`pwd`

setup() {
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
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmttoken run $DIR/bin/contentful -v migrate

  assert_failure  

  log "$output"
  unstub ts-node
}

@test 'does not run comparison if migration fails' {
  stub ts-node \
    "--skip-project node_modules/.bin/contentful-migration -s testspace -a mgmt-token -p db/migrate : false" 
  ln -f -s ${BATS_MOCK_BINDIR}/ts-node node_modules/.bin/ts-node

  # act
  CONTENTFUL_SPACE_ID=testspace CONTENTFUL_MANAGEMENT_TOKEN=mgmt-token run $DIR/bin/contentful -v migrate

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
    run $DIR/bin/contentful -v migrate -s testspace2 -a mgmt-token-2 -e testenv migration_folder

  assert_failure
  refute_output --partial contentful-export

  unstub ts-node
}