#!/usr/bin/env bash

select_from_table() {
  local tableName dbfile col val rc header lines

  read -r -p "Enter the table name to select from: " tableName

  dbfile="${DB_ROOT}/${CURRENT_DB}/${tableName}.db"

  if [[ ! -f "$dbfile" ]]; then
    print_error "Table '$tableName' does not exist."
    return 1
  fi

  # Show header and row count first to allow informed filtering
  header=$(head -n1 "$dbfile" 2>/dev/null || echo "")
  lines=$(wc -l <"$dbfile" 2>/dev/null || echo 0)

  if [[ -z "$header" ]]; then
    print_warning "Table is empty or malformed."
    return 0
  fi

  print_header "Columns: $header"
  print_header "Rows: $((lines - 1))"

  if [[ "$lines" -le 1 ]]; then
    print_warning "Table is empty"
    return 0
  fi

  if confirm_prompt "Filter by column?" ; then
    read -r -p "Enter column name or index to filter by: " col
    if [[ -z "$col" ]]; then
      print_error "No column provided."
      return 1
    fi

    read -r -p "Enter value to match: " val
    if [[ -z "$val" ]]; then
      print_error "No value provided."
      return 1
    fi

    print_header "Filtered results: $col = $val"
    print_table_formatted "$dbfile" "$col" "$val"
    rc=$?
    if [[ $rc -ne 0 ]]; then
      return $rc
    fi
    return 0
  fi

  # No filter -> print full table
  print_header "Contents of table: $tableName"
  print_table_formatted "$dbfile"
  rc=$?
  return $rc
}

