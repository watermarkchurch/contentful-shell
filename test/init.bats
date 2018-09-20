#!/usr/bin/env bats

load 'test_helper/utils'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'test_helper/mocks/stub'

DIR=`pwd`

setup() {
  stub_node_deps
}

# teardown() {
# }

@test 'inits npm & node deps' {  
  stub npm \
    'init : touch package.json' \
    'install --save-dev github:watermarkchurch/migration-cli : touch node_modules/.bin/contentful-migration' \
    'install --save-dev typescript ts-node : touch node_modules/.bin/ts-node' \
    'install --save-dev contentful-cli : touch node_modules/.bin/contentful' \

  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  mkdir -p node_modules/.bin

  # act
  run $DIR/bin/contentful -v init

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/node_modules/.bin/contentful-migration
  assert_file_exist $BATS_TMPDIR/init/node_modules/.bin/ts-node
  assert_file_exist $BATS_TMPDIR/init/node_modules/.bin/contentful

  unstub npm
}

@test 'inits bin/release' {
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  stub_node_deps
  # act
  run $DIR/bin/contentful -v init

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/bin/release
  contents=$(cat $BATS_TMPDIR/init/bin/release)
  [[ $contents = *'contentful migrate -y'* ]]
}

@test 'updates existing bin/release' {
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
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

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/bin/release
  contents=$(cat $BATS_TMPDIR/init/bin/release)
  [[ $contents = *'contentful migrate -y'* ]]
}

@test 'doesnt touch a bin/release that already calls bin/contentful' {
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
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

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/bin/release
  
  contents=$(cat $BATS_TMPDIR/init/bin/release)
  [[ $contents != *'contentful migrate -y'* ]]
}

@test 'updates Procfile' {
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  stub_node_deps

  cat <<- 'EOF' > Procfile
web: bundle exec rails s
EOF

  # act
  run $DIR/bin/contentful -v init

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/Procfile
  
  contents=$(cat $BATS_TMPDIR/init/Procfile)
  [[ $contents = *'release: bin/release'* ]]
}

@test 'does not overwrite existing release command in Procfile' {
  rm -rf $BATS_TMPDIR/init
  mkdir -p $BATS_TMPDIR/init

  pushd $BATS_TMPDIR/init
  touch ~/.contentfulrc.json
  stub_node_deps

  cat <<- 'EOF' > Procfile
web: bundle exec rails s
release: bin/release
EOF

  # act
  run $DIR/bin/contentful -v init

  popd

  assert_success
  assert_file_exist $BATS_TMPDIR/init/Procfile
  
  count=$(grep 'release: bin/release' $BATS_TMPDIR/init/Procfile | wc -l)
  [[ ${count//[[:space:]]/} = '1' ]]
}