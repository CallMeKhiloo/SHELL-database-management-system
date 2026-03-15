#!/usr/bin/env bash

connect_to_database() {
  if ! list_databases >/dev/null 2>&1; then
    return 1
  fi

  local name
  read -r -p "Enter database name to connect: " name

  if [ -z "${name}" ]; then
    print_error "No name provided."
    return 1
  fi

  if [ ! -d "${DB_ROOT}/$name" ]; then
    print_error "Database '$name' does not exist."
    return 1
  fi

  CURRENT_DB="$name"
  export CURRENT_DB
  print_success "Connected to database '$name'."
  return 0
}
