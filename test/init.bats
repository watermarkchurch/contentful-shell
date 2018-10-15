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
}

teardown() {
  popd
}

@test 'inits npm & node deps' {  
  stub npm \
    'init : touch package.json' \
    'install --save-dev github:watermarkchurch/contentful-migration : touch node_modules/.bin/contentful-migration' \
    'install --save-dev typescript ts-node : touch node_modules/.bin/ts-node' \
    'install --save-dev contentful-cli : touch node_modules/.bin/contentful' \

  mkdir -p node_modules/.bin

  # act
  run $DIR/bin/contentful -v init

  assert_success
  assert_file_exist node_modules/.bin/contentful-migration
  assert_file_exist node_modules/.bin/ts-node
  assert_file_exist node_modules/.bin/contentful

  unstub npm
}

@test 'inits bin/release' {
  stub_node_deps
  # act
  run $DIR/bin/contentful -v init


  assert_success
  assert_file_exist bin/release
  contents=$(cat bin/release)
  [[ $contents = *'contentful migrate -y'* ]]
}

@test 'updates existing bin/release' {
  stub_node_deps

  mkdir -p bin
  cat <<- 'EOF' > bin/release
#! bin/sh

set -e

echo "Migrating database..."
bundle exec rake db:migrate
EOF

  # act
  run $DIR/bin/contentful -v init

  assert_success
  assert_file_exist bin/release
  contents=$(cat bin/release)
  [[ $contents = *'contentful migrate -y'* ]]
}

@test 'doesnt touch a bin/release that already calls bin/contentful' {
  stub_node_deps

  mkdir -p bin
  cat <<- 'EOF' > bin/release
#! bin/sh

set -e

echo "Migrating database..."
bundle exec rake db:migrate

bin/contentful -v migrate -y
EOF

  # act
  run $DIR/bin/contentful -v init


  assert_success
  assert_file_exist bin/release
  
  contents=$(cat bin/release)
  [[ $contents != *'contentful migrate -y'* ]]
}

@test 'updates Procfile' {
  stub_node_deps

  cat <<- 'EOF' > Procfile
web: bundle exec rails s
EOF

  # act
  run $DIR/bin/contentful -v init

  assert_success
  assert_file_exist Procfile
  
  contents=$(cat Procfile)
  [[ $contents = *'release: bin/release'* ]]
}

@test 'does not overwrite existing release command in Procfile' {
  stub_node_deps

  cat <<- 'EOF' > Procfile
web: bundle exec rails s
release: bin/release
EOF

  # act
  run $DIR/bin/contentful -v init

  assert_success
  assert_file_exist Procfile
  
  count=$(grep 'release: bin/release' Procfile | wc -l)
  [[ ${count//[[:space:]]/} = '1' ]]
}

@test 'adds contentful-* to gitignore' {
  stub_node_deps
  
  # act
  run $DIR/bin/contentful -v init

  assert_success
  assert_file_exist .gitignore
  
  count=$(grep 'contentful-*' .gitignore | wc -l)
  [[ ${count//[[:space:]]/} = '1' ]]
}