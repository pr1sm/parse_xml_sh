#!/bin/sh

# Setup trap to remove all references
if [ "$__util_trap_created" = "" ]; then
  __util_trap_created="1"
  [ -z "$TMPDIR" ] && TMPDIR="/tmp"
  if [ "$(echo -n "$TMPDIR" | tail -c 1)" = "/" ]; then
    trap "rm -rf ${TMPDIR}__ref_*" EXIT
  else
    trap "rm -rf ${TMPDIR}/__ref_*" EXIT
  fi
fi

util_make_ref() {
  [ "$#" != "1" ] && return 1
  local ref="$(mktemp -dt "__ref_${1}.XXXXXXXX")"
  echo "$(basename -- "$ref")"
  return 0
}