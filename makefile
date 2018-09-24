.PHONY: test
test: test/test_helper/%/%.bash
	bats test/*.bats

.PHONY: test-watch
test-watch: test/test_helper/%/%.bash
	nodemon -e bats --watch bin/contentful --watch test/ --exec 'bats test/* || echo "failed"'

.PHONY: lint
lint:
	shellcheck bin/contentful

test/test_helper/%/%.bash:
	git submodule update --init