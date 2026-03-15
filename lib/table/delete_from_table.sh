#!/usr/bin/env bash

delete_from_table() {
  local tableName dbfile header lines col val count tmp rc

  read -r -p "Enter the table name to delete from: " tableName

  dbfile="${DB_ROOT}/${CURRENT_DB}/${tableName}.db"

  if [[ ! -f "$dbfile" ]]; then
    print_error "Table '$tableName' does not exist."
    return 1
  fi

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

  if ! confirm_prompt "Filter by column before deleting?"; then
    # No filter -> delete all rows but keep header
    if confirm_prompt "Are you sure you want to delete ALL rows from table '$tableName'?"; then
      tmp=$(mktemp) || {
        print_error "Failed to create temporary file."
        return 1
      }

      trap 'rm -f "${tmp}"' RETURN
      head -n1 "$dbfile" >"$tmp" && mv "$tmp" "$dbfile"
      trap - RETURN
      print_success "All rows deleted from '$tableName'."
      return 0
    fi

    print_warning "Operation cancelled."
    return 2
  fi

  # Filter before delete
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

  # Count matching rows. prints -1 on column-not-found
  count=$(awk -f "${PROJECT_ROOT}/lib/awk/count_rows.awk" -v col="$col" -v val="$val" "$dbfile")

  if [[ "$count" == "-1" ]]; then
    print_error "Column '$col' not found."
    return 2
  fi

  if [[ "$count" -eq 0 ]]; then
    print_warning "No matching rows found for '$col' = '$val'."
    return 0
  fi

  print_header "About to delete $count matching row(s) from '$tableName'."
  if ! confirm_prompt "Proceed with deletion?"; then
    print_warning "Operation cancelled."
    return 2
  fi

  tmp=$(mktemp) || {
    print_error "Failed to create temporary file."
    return 1
  }
  trap 'rm -f "${tmp}"' RETURN

  # Write header + non-matching rows to temporary file, then atomically move into place.
  awk -f "${PROJECT_ROOT}/lib/awk/delete_rows.awk" -v col="$col" -v val="$val" -v tmp="$tmp" "$dbfile"
  rc=$?

  if [[ $rc -ne 0 ]]; then
    print_error "Failed to delete matching rows."
    rm -f "$tmp" 2>/dev/null || true
    return 1
  fi

  mv "$tmp" "$dbfile"
  trap - RETURN
  print_success "Deleted $count row(s) from '$tableName'."
  return 0
}
