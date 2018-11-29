#!/bin/sh
# Stack Data Structure written for POSIX Compliant Shells
# Author: Srinivas Dhanwada <dhanwada.dev@gmail.com>

# source the map/list methods
. ./map.sh
. ./list.sh

# stack methods implemented using an underlying list

stack_push() {
  [ "$#" != 2 ] && return 1
  echo "$(list_push "$1" "$2")"
  return "$?"
}

stack_pop() {
  [ "$#" != 1 ] && return 1
  echo "$(list_pop "$1")"
  return "$?"
}

stack_size() {
  [ "$#" != 1 ] && return 1
  echo "$(list_size "$1")"
  return "$?"
}

stack_peek() {
  [ "$#" != 1 ] && return 1
  local idx="$(map_get "$1" "__idx")"
  [ "$?" != 0 ] || [ "x${idx}x" = "xx" ] && return 1
  [ "x${idx}x" = "x0x" ] && return 1
  idx="$(($idx - 1))"
  echo "$(map_get "$1" "$idx")"
  return 0
}
