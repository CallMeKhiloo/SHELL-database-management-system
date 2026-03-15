#!/usr/bin/env bash

list_tables() {
  print_header "Tables in Database: $CURRENT_DB"

  local tables
  tables=$(ls "${DB_ROOT}/${CURRENT_DB}"/*.meta 2>/dev/null)

  if [[ -z "$tables" ]]; then
    print_error "No tables found in this database."
    return 0
  fi

  for table in $tables; do # here $tables is unquoted so we can iterate over each file
    echo "- $(basename "$table" .meta)"
  done
}

