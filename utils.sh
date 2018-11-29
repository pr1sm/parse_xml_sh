#!/bin/sh

# Setup trap to remove all references
if [ "$__util_trap_created" = "" ]; then
  __util_trap_created="1"
  trap 'rm -rf /tmp/__ref_*' EXIT
fi

util_make_ref() {
  [ "$#" != "1" ] && return 1
  local ref="$(mktemp -dt "__ref_${1}.XXXXXXXX")"
  echo "$(basename -- "$ref")"
  return 0
}