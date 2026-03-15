#!/usr/bin/env bash

drop_database() {
  if ! list_databases >/dev/null 2>&1; then
    print_warning "No databases to drop."
    return 0
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

  print_warning "Aborted."
  return 2
}
