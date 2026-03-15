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
