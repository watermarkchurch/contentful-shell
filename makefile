.PHONY: test
test: test/test_helper/%/%.bash
	bats test/*.bats

test/test_helper/%/%.bash:
	git submodule update --init