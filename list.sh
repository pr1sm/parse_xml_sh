#!/bin/sh
# List Data Structure written for POSIX Compliant Shells
# Author: Srinivas Dhanwada <dhanwada.dev@gmail.com>

# source the map methods
. ./map.sh

# list methods implemented using an underlying map

list_all() {
  [ "$#" -lt 1 ] || [ "$#" -ge 4 ] && return 1
  local start=0
  local stop="$(map_get "$1" "__idx")"
  local __list_return=""
  ! [ "$?" -eq 0 ] && return 1
  [ "$#" -ge 2 ] && [ "$2" -ge "$start" ] && [ "$2" -lt "$stop" ] && start="$2"
  [ "$#" -eq 3 ] && [ "$3" -ge "$start" ] && [ "$3" -lt "$stop" ] && stop="$3"
  local idx="$start"
  while ! [ "$idx" -eq "$stop" ]; do
    local val="$(map_get "$1" "$idx")"
    if [ "$?" -eq 0 ]; then
      if [ "$idx" -eq "$start" ]; then
        __list_return="$val"
      else
        __list_return="${__list_return} $val"
      fi
    fi
    idx="$(($idx + 1))"
  done
  echo "$__list_return"
  return 0
}

list_size() {
  local size=0
  [ "$#" != 1 ] && return 1
  size="$(map_get "$1" "__idx")"
  [ "x${size}x" = "xx" ] && size=0
  retval="$?"
  # echo "LIST_SIZE: $1: $retval: $size" >&2
  [ "$retval" != 0 ] && echo "$size" && return 1
  echo "$size"
  return 0
}


list_clear() {
  [ "$#" != 1 ] && return 1
  local prev_size="$(map_get "$1" "__idx")"
  ! [ "$?" -eq 0 ] && return 1
  map_put "$1" "__idx" "0" > /dev/null
  echo "$prev_size"
  return 0
}

list_insert() {
  [ "$#" != 3 ] && return 1
  local size="$(map_get "$1" "__idx")"
  ! [ "$?" -eq 0 ] && return 1
  [ "$2" -lt 0 ] || [ "$2" -gt "$size" ] && return 1
  if [ "$2" -eq "$size" ]; then
    list_push "$1" "$3" > /dev/null
    return "$?"
  fi
  map_put "$1" "$2" "$3" > /dev/null
  local retval="$?"
  echo "$size"
  return "$retval"
}

list_get() {
  [ "$#" != 2 ] && return 1
  local size="$(map_get "$1" "__idx")"
  ! [ "$?" -eq 0 ] && return 1
  [ "$2" -lt 0 ] || [ "$2" -ge "$size" ] && return 1
  echo "$(map_get "$1" "$2")"
  return "$?"
}

list_push() {
  [ "$#" != 2 ] && return 1
  local idx="$(map_get "$1" "__idx")"
  [ "$?" != 0 ] || [ "x${idx}x" = "xx" ] && map_put "$1" "__idx" "0" > /dev/null
  idx="$(map_get "$1" "__idx")"
  map_put "$1" "$idx" "$2" > /dev/null
  idx="$(($idx + 1))"
  map_put "$1" "__idx" "$idx" > /dev/null
  echo "$idx"
  return 0
}

list_pop() {
  [ "$#" != 1 ] && return 1
  local idx="$(map_get "$1" "__idx")"
  [ "$?" != 0 ] || [ "x${idx}x" = "xx" ] || [ "x${idx}x" = "x0x" ] && return 1
  idx="$(($idx - 1))"
  echo "$(map_get "$1" "$idx")"
  map_put "$1" "__idx" "$idx" > /dev/null
  return 0
}

list_shift() {
  [ "$#" != 1 ] && return 1
  local idx="$(map_get "$1" "__idx")"
  [ "$?" != 0 ] || [ "x${idx}x" = "x0x" ] return 1
  if [ "$idx" -eq 1 ]; then
    echo "$(list_pop "$1")"
    return "$?"
  fi
  retval="$(map_get "$1" "0")"
  idx=0
  local sublist="$(list_all "$1" 1)"
  for val in $sublist; do
    list_insert "$1" "$idx" "$val" > /dev/null
    idx="$(($idx + 1))"
  done
  list_pop "$1" > /dev/null
  echo "$retval"
  return 0
}

list_unshift() {
  [ "$#" != 2 ] && return 1
  map_get "$1" "__idx" > /dev/null
  ! [ "$?" -eq 0 ] && map_put "$1" "__idx" "0"
  local prev_list="$(list_all "$1")"
  list_clear "$1" > /dev/null
  list_push "$1" "$2" > /dev/null
  for val in $prev_list; do
    list_push "$1" "$val" > /dev/null
  done
  echo "$(list_size "$1")"
  return "$?"
}
