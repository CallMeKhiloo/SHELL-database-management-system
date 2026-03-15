#!/usr/bin/env bash

DB_ROOT="${PROJECT_ROOT}/DBs"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (Reset)

print_header() {
  echo -e "${CYAN}==> $*${NC}" # NC at the end to reset the color for rest of the terminal
}

print_success() {
  echo -e "${GREEN}$*${NC}"
}

print_error() {
  echo -e "${RED}$*${NC}" >&2
}

print_warning() {
  echo -e "${YELLOW}$*${NC}"
}

validate_name() {
  local name="$1"

  if [[ -z "${name}" ]]; then
    return 1
  fi

  if [[ "${name}" =~ ^[A-Za-z0-9_]+$ ]]; then
    return 0
  fi

  return 1
}

validate_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

validate_date() {
  # check the format first
  if [[ ! "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 1
  fi

  # -d to check the provided string not "now", then we discard the output and error
  if date -d "$1" "+%Y-%m-%d" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

confirm_prompt() {
  local prompt="$1"

  read -r -p "$prompt [y/N]: " ans

  if [[ "$ans" == [Yy] || "$ans" == [Yy][Ee][Ss] ]]; then
    return 0
  fi

  return 1
}

load_schema() {
  local tableName="$1"
  local metaFile="${DB_ROOT}/${CURRENT_DB}/${tableName}.meta"

  if [[ ! -f "$metaFile" ]]; then
    print_error "Table schema not found."
    return 1
  fi

  cat "$metaFile" | tr ',' '\n'
}

# Usage: print_table_formatted <dbfile> [filter_column_or_index] [filter_value]
print_table_formatted() {
  local dbfile="$1"
  local filter_col="${2-}"
  local filter_val="${3-}"

  # Delegate formatting logic to a standalone AWK script for readability
  awk -f "${PROJECT_ROOT}/lib/awk/format_table.awk" -v col="$filter_col" -v val="$filter_val" "$dbfile"

  rc=$?
  case $rc in
  0) return 0 ;;
  2)
    print_warning "Table is empty."
    return 0
    ;;
  3)
    print_error "Column '$filter_col' not found."
    return 2
    ;;
  4)
    print_warning "No matching rows found for '$filter_col' = '$filter_val'."
    return 0
    ;;
  *)
    print_error "An unexpected formatting error occurred (Code: $rc)."
    return 1
    ;;
  esac
}
