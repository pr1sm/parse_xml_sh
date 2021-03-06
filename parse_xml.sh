#!/bin/sh

# source methods
. ./utils.sh
. ./map.sh
. ./list.sh
. ./stack.sh

echod() {
  ! [ -z "$_OPT_DEBUG" ] && echo $@ >&2
}

print_map() {
  [ "$#" -lt 1 ] || [ "$#" -gt 2 ] && return 1
  local spacer=""
  if [ "$#" -eq 2 ] && [ "x${2}x" != "xx" ]; then
    spacer="$2"
  fi
  local list_return="$(list_all "$1")"
  [ "$?" != 0 ] && return 1
  for ref in $list_return; do
    if [ "$(echo "$ref" | grep -E "^__ref_")" != "" ]; then
      # echo "${spacer}REF: ${tag}" >&2
      local tag="$(map_get "$ref" "tag")"
      if [ "$?" -eq 0 ]; then
        echo "${spacer}TAG: $tag"
      fi
      local val="$(map_get "$ref" "value")"
      if [ "$?" -eq 0 ]; then
        echo "${spacer}VALUE: $val"
      fi
      if [ "$(list_size "$ref")" != 0 ]; then
        echo "${spacer}CONTENT:"
        print_map "$ref" "${spacer}  "
      fi
    else
      echo "${spacer}VALUE: $ref"
    fi
    if [ "x${spacer}x" = "xx" ]; then
      echo ""
    fi
  done
}

parse_xml() {
  # Initialize Variables
  local CURR_TAG_NAME=""
  local TAG_NAME_STACK="PARSE_XML_TAG_NAME_STACK"
  local CURR_TAG_MAP=""
  local TAG_MAP_STACK="PARSE_XML_TAG_MAP_STACK"
  local ISCOMMENT="0"

  # Create empty map to store parsed results
  CURR_TAG_MAP="$(util_make_ref "parsed")"
  echod "CURR_TAG_MAP initialized to: $CURR_TAG_MAP"

  # Start Parsing
  while read -r LINE; do
    echod "Starting parse for: $LINE"
    # Check if we have an empty line
    if [ "x${LINE}x" = "xx" ]; then
      echod "Empty line, continuing..."
      continue
    fi

    # Check for comments in the form <!-- * --> or <? * ?>
    if [ "$(echo "<$LINE" | grep -E "^(<\?|<!--)")" != "" ]; then
      ISCOMMENT="1"
      echod "Comment Start Found! Skipping until comment end is found..."
    fi
    if [ "$ISCOMMENT" = "1" ]; then
      if [ "$(echo "<$LINE" | grep -E "(\?>|-->)$")" != "" ]; then
        ISCOMMENT="0"
        echod "Comment End Found! Resuming normal parsing..."
      fi
      continue
    fi

    # Split the line into an entity (tag + attributes) and value (content)
    local ORIG_IFS="$IFS"
    IFS=\>
    read -r RAW_ENTITY RAW_VALUE <<EOF
$LINE
EOF
    IFS="$ORIG_IFS"

    # Trim surrounding whitespace
    local ENTITY="$(echo "$RAW_ENTITY" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    local VALUE="$(echo "$RAW_VALUE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    
    # discard attributes if they exist
    local TAG="$(echo "$ENTITY" | cut -f1 -d" ")"

    echod "Parts Determined: tag: |$TAG| value: |$VALUE| entity: |$ENTITY|"

    # Check if the tag closes our current tag
    if [ "x${TAG}x" = "x/${CURR_TAG_NAME}x" ]; then
      CURR_TAG_NAME=""
      if [ "$(stack_size "$TAG_NAME_STACK")" != 0 ]; then 
        CURR_TAG_NAME="$(stack_pop "$TAG_NAME_STACK")"
      fi

      echod "Closing tag determined, current tag updated to: $CURR_TAG_NAME"

      if [ "$(stack_size "$TAG_MAP_STACK")" != 0 ]; then
        local prev_map="$(stack_pop "$TAG_MAP_STACK")"
        list_push "$prev_map" "$CURR_TAG_MAP" > /dev/null
        CURR_TAG_MAP="$prev_map"
        echod "Tag stack added, current tag map updated to $CURR_TAG_MAP"
      fi
      continue
    fi

    # Check if this is a closing tag -- if so, we have an invalid format
    if [ "x$(echo "$TAG" | cut -c 1-1)x" = "x/x" ]; then
      echod "Invalid Format determined! Non-matching tag found: $TAG"
      return 1
    fi

    # Tag is not a closing tag, It must be a nested tag
    echod "tag: $TAG determined as nested tag"
    stack_push "$TAG_NAME_STACK" "$CURR_TAG_NAME" > /dev/null
    CURR_TAG_NAME="$TAG"
    stack_push "$TAG_MAP_STACK" "$CURR_TAG_MAP" > /dev/null
    CURR_TAG_MAP="$(util_make_ref "$TAG")"
    map_put "$CURR_TAG_MAP" "tag" "$TAG" > /dev/null

    echod "Current tag updated: |$TAG|"
    echod "Current tag map updated: |$CURR_TAG_MAP|"

    if [ "x${VALUE}x" != "xx" ]; then
      echod "Pushing value onto current tag map: $VALUE"
      map_put "$CURR_TAG_MAP" "value" "$VALUE" > /dev/null
    fi
  done
  # Check for invalid structure
  if [ "$(stack_size "$TAG_NAME_STACK")" != "0" ]; then
    echod "Invalid structure determined!"
    return 1
  fi

  echo "$CURR_TAG_MAP"

  return 0
}

_OPT_PRINT=""
_OPT_HELP=""
_OPT_DEBUG=""

USAGE="${0} [-p] <file.xml>
  -p - Print summary
  -d - Print debug output"

while getopts :phd _OPT 2>/dev/null; do
  case ${_OPT} in
    p) _OPT_PRINT="1" ;;
    h) _OPT_HELP="1" ;;
    d) _OPT_DEBUG="1" ;;
    *) _NOARGS="${_NOARGS}${_NOARGS+, }-${OPTARG}" ;;
  esac
done
shift $((OPTIND - 1))

! [ -z "$_OPT_HELP" ] && echo "$USAGE" && exit 0

if [ "$#" -ne 1 ]; then
  echo "Error: Invalid Parameter. see -h for usage"
  exit 1
fi

FILE="$1"
! [ -f "$FILE" ] && echo "Error: File doesn't exist." && exit 1
# FILE_CONTENT="$(sed ':a;N;$!ba;s/\r\n//g' "$FILE" | sed 's/</\\n/g')"
# This usage of sed is more portable...
FILE_CONTENT="$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' "$FILE" | tr '<' '\n')"

echod "$FILE_CONTENT"

PARSED="$(echo "${FILE_CONTENT}" | parse_xml)"
if [ "$?" -ne 0 ]; then
  echo "Error: Invalid XML"
  exit 1
fi

! [ -z "$_OPT_PRINT" ] && print_map "$PARSED"
