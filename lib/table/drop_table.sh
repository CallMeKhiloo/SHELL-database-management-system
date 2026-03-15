#!/usr/bin/env bash

drop_table() {
  local tableName

  read -r -p "Enter the table name to drop: " tableName

  if [[ ! -f "${DB_ROOT}/${CURRENT_DB}/${tableName}.meta" ]]; then
    print_error "Table '$tableName' does not exist."
    return 1
  fi

  if confirm_prompt "Are you sure you want to drop table '$tableName'? This action cannot be undone."; then
    rm -f "${DB_ROOT}/${CURRENT_DB}/${tableName}.meta" "${DB_ROOT}/${CURRENT_DB}/${tableName}.db"
    print_success "Table '$tableName' dropped successfully."
    return 0
  fi

  print_warning "Operation cancelled."
  return 2
}

