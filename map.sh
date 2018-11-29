#!/bin/sh
# Map Data Structure for POSIX Compliant Shells
# Author: Srinivas Dhanwada <dhanwada.dev@gmail.com>

# source util script to setup reference cleanup
. ./utils.sh

# map methods adapted from:
# https://stackoverflow.com/questions/688849/associative-arrays-in-shell-scripts

if [ "$__map_prefix" = "" ]; then
  __map_prefix="$(basename -- "$0")"
fi
if [ "$__map_mapdir" = "" ]; then
  __map_mapdir="$(mktemp -dt "__ref_${__map_prefix}XXXXX")"
  # trap 'rm -rf /tmp/__ref_*' EXIT
fi

map_get() {
  [ "$#" != "2" ] && return 1
  local mapname="$1"; local key="$2"
  # echo "map_get called: [$1, $2]" >&2
  local __map_return="$(cat "${__map_mapdir}/${mapname}/${key}" 2>/dev/null)"
  if [ "x${__map_return}x" = "xx" ]; then
    return 1
  fi
  echo "$__map_return"
  return 0
}

map_put() {
  [ "$#" != "3" ] && return 1
  local mapname="$1"; local key="$2"; local value="$3"
  # echo "map_put called: [$1, $2, $3]" >&2
  echo "$(map_get "$mapname" "$key")"
  [ -d "${__map_mapdir}/${mapname}" ] || mkdir "${__map_mapdir}/${mapname}"
  echo "$value" > "${__map_mapdir}/${mapname}/${key}"
  return 0
}
