#!/usr/bin/env bash

create_database() {
  local dbName
  read -r -p "Enter the database name: " dbName

  if ! validate_name "$dbName"; then
    print_error "Invalid database name. Use only letters, numbers and underscores."
    return 1
  fi

  if [ -d "${DB_ROOT}/$dbName" ]; then
    print_error "Database '$dbName' already exists."
    return 1
  fi

  if mkdir -p "${DB_ROOT}/$dbName"; then
    print_success "Database '$dbName' created successfully."
    return 0
  fi

  print_error "Failed to create database '$dbName'."
  return 1
}

list_databases() {
  print_header "Databases"

  if [ ! -d "${DB_ROOT}" ]; then
    print_error "No databases found."
    return 1
  fi

  local -a dbs
  mapfile -t dbs < <(find "${DB_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort)

  if [ ${#dbs[@]} -eq 0 ]; then
    print_error "No databases found."
    return 1
  fi

  local i
  for i in "${!dbs[@]}"; do
    printf "%3d) %s\n" $((i + 1)) "${dbs[$i]}"
  done

  return 0
}

drop_database() {
  if ! list_databases >/dev/null 2>&1; then
    print_error "No databases to drop."
    return 1
  fi

  local name
  read -r -p "Enter the database name to drop: " name

  if [ -z "${name}" ]; then
    print_error "No name provided."
    return 1
  fi

  if [ ! -d "${DB_ROOT}/$name" ]; then
    print_error "Database '$name' does not exist."
    return 1
  fi

  if confirm_prompt "Are you sure you want to permanently delete database '$name'?"; then
    # :? checkes if variable is not empty so it doesn't run rm -rf / by accident
    if rm -rf "${DB_ROOT:?}/${name:?}"; then
      print_success "Database '$name' removed."
      return 0
    fi

    print_error "Failed to remove database '$name'."
    return 1
  fi

  print_header "Aborted."
  return 2
}

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
