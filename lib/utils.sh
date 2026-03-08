#!/usr/bin/env bash

DB_ROOT="./DBs"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (Reset)

print_header() {
  echo -e "${CYAN}==> $*${NC}"
}

print_success() {
  echo -e "${GREEN}$*${NC}"
}

print_error() {
  echo -e "${RED}$*${NC}" >&2
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

confirm_prompt() {
  local prompt="$1"

  read -r -p "$prompt [y/N]: " ans

  if [[ "$ans" == [Yy] || "$ans" == [Yy][Ee][Ss] ]]; then
    return 0
  fi

  return 1
}
