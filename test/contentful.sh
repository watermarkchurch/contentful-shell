#!/usr/bin/env bats

@test "prints help" {
  run bin/contentful -h
  echo "${lines[1]}"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" =  "bin/contentful <command> [opts]" ]
}