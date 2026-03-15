#!/usr/bin/env bash

list_databases() {
  print_header "Databases"

  if [ ! -d "${DB_ROOT}" ]; then
    print_warning "No databases found."
    return 0
  fi

  local -a dbs
  mapfile -t dbs < <(find "${DB_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort)

  if [ ${#dbs[@]} -eq 0 ]; then
    print_warning "No databases found."
    return 0
  fi

  local i
  for i in "${!dbs[@]}"; do
    printf "%3d) %s\n" $((i + 1)) "${dbs[$i]}"
  done

  return 0
}
