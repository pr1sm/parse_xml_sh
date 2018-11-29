#!/bin/sh

# source methods
. ./utils.sh
. ./map.sh
. ./list.sh
. ./stack.sh

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

  # Start Parsing
  while read -r LINE; do
    # Check if we have an empty line
    if [ "x${LINE}x" = "xx" ]; then
      continue
    fi

    # Check for comments in the form <!-- * --> or <? * ?>
    if [ "$(echo "<$LINE" | grep -E "^(<\?|<!--)")" != "" ]; then
      ISCOMMENT="1"
    fi
    if [ "$ISCOMMENT" = "1" ]; then
      if [ "$(echo "<$LINE" | grep -E "(\?>|-->)$")" != "" ]; then
        ISCOMMENT="0"
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

    # Check if the tag closes our current tag
    if [ "x${TAG}x" = "x/${CURR_TAG_NAME}x" ]; then
      CURR_TAG_NAME=""
      if [ "$(stack_size "$TAG_NAME_STACK")" != 0 ]; then 
        CURR_TAG_NAME="$(stack_pop "$TAG_NAME_STACK")"
      fi

      if [ "$(stack_size "$TAG_MAP_STACK")" != 0 ]; then
        local prev_map="$(stack_pop "$TAG_MAP_STACK")"
        list_push "$prev_map" "$CURR_TAG_MAP" > /dev/null
        CURR_TAG_MAP="$prev_map"
      fi
      continue
    fi

    # Check if this is a closing tag -- if so, we have an invalid format
    if [ "x$(echo "$TAG" | cut -c 1-1)x" = "x/x" ]; then
      return 1
    fi

    # Tag is not a closing tag, It must be a nested tag
    stack_push "$TAG_NAME_STACK" "$CURR_TAG_NAME" > /dev/null
    CURR_TAG_NAME="$TAG"
    stack_push "$TAG_MAP_STACK" "$CURR_TAG_MAP" > /dev/null
    CURR_TAG_MAP="$(util_make_ref "$TAG")"
    map_put "$CURR_TAG_MAP" "tag" "$TAG" > /dev/null

    if [ "x${VALUE}x" != "xx" ]; then
      map_put "$CURR_TAG_MAP" "value" "$VALUE" > /dev/null
    fi
  done
  # Check for invalid structure
  if [ "$(stack_size "$TAG_NAME_STACK")" != "0" ]; then
    echo "invalid structure!"
    return 1
  fi

  print_map "$CURR_TAG_MAP"

  return 0
}

__OPT_LIGHT=false
__OPT_FORCE_PRINT=false
__OPT_XAPPLY=false
__GET_CONTENT=false

USAGE="${FUNCNAME} [-clp] [-x command <-a attribute>] <file.xml> [tag | \"any\"] [attributes .. | \"content\"]
  -c = NOCOLOR
  -l = LIGHT (no \"attributes\" printed)
  -p = FORCE PRINT (when no attributes given)
  -x apply a command on an attribute and print the result instead of the former value
  (no attribute given will load their values into your shell; use '-p' to print them as well"

FILE_CONTENT="$(sed ':a;N;$!ba;s/\n//g' "test.xml" | sed 's/</\n/g')"
echo "${FILE_CONTENT}" | parse_xml