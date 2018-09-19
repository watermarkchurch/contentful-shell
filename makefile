.PHONY: test
test: test/test_helper/%/load.bash
	bats test/*.bats

test/test_helper/%/load.bash:
	git submodule update --init