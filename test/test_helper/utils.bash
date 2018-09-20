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

stub_node_deps() {
  [[ -f package.json ]] || echo "{}" > package.json
  mkdir -p node_modules/.bin/
  touch node_modules/.bin/contentful-migration \
        node_modules/.bin/ts-node \
        node_modules/.bin/contentful-export \
        node_modules/.bin/contentful-import \
        node_modules/.bin/contentful
}