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

create_table() {
  local tableName colName colType isPK="" pkSelected="false" schema=""
  read -r -p "Enter the table name: " tableName

  if ! validate_name "$tableName"; then
    print_error "Invalid table name. Use only letters, numbers and underscores."
    return 1
  fi

  if [[ -f "${DB_ROOT}/${CURRENT_DB}/${tableName}.meta" ]]; then
    print_error "Table '$tableName' already exists."
    return 1
  fi

  print_header "Defining Columns for $tableName (Type 'done' when finished)"

  while true; do
    read -r -p "Enter Column Name (or 'done'): " colName
    [[ "$colName" == "done" ]] && break

    if ! validate_name "$colName"; then
      print_error "Invalid column name."
      continue
    fi

    echo "Select Type for '$colName':"
    select type in "INT" "STR" "DATE"; do
      case $type in
      INT | STR | DATE)
        colType=$type
        break
        ;;
      *) print_error "Invalid selection. Please choose 1, 2, or 3." ;;
      esac
    done

    if [[ "$pkSelected" == "false" ]]; then
      if confirm_prompt "Set '$colName' as Primary Key?"; then
        isPK="PK"
        pkSelected="true"
      fi
    fi

    schema+="$colName:$colType:$isPK,"
  done

  if [[ -z "$schema" ]]; then
    print_error "Table must have at least one column."
    return 1
  fi

  schema="${schema%,}" # Remove trailing comma

  if [[ "$pkSelected" == "false" ]]; then
    print_error "Table must have a primary key."
    return 1
  fi

  echo -ne "$schema" >"${DB_ROOT}/${CURRENT_DB}/${tableName}.meta"

  local header
  header=$(echo "$schema" | tr ',' '\n' | cut -d: -f1 | paste -sd '|' -)
  echo "$header" >"${DB_ROOT}/${CURRENT_DB}/${tableName}.db"

  print_success "Table '$tableName' created successfully."
  return 0
}

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

  if confirm_prompt "Filter by column?"; then
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

insert_into_table() {
  local tableName rowData="" currentCol=0

  read -r -p "Enter the table name to insert into: " tableName

  mapfile -t schema < <(load_schema "$tableName") # mapfile handles the multi-line output from load_schema and stores it in an array

  if [[ ${#schema[@]} -eq 0 ]]; then
    print_error "Table '$tableName' does not exist or has no schema."
    return 1
  fi

  for col in "${schema[@]}"; do
    IFS=':' read -r colName colType isPK <<<"$col" # IFS is the internal field separator

    while true; do
      read -r -p "Enter value for $colName ($colType)${isPK:+ [PK]}: " val

      if [[ -z "$val" ]]; then
        print_error "Value cannot be empty."
        continue
      fi

      case $colType in
      INT)
        if ! validate_int "$val"; then
          print_error "Invalid integer value."
          continue
        fi
        ;;
      STR)
        if ! validate_name "$val"; then
          print_error "Invalid string value. Use only letters, numbers and underscores."
          continue
        fi
        ;;
      DATE)
        if ! validate_date "$val"; then
          print_error "Invalid date format. Use YYYY-MM-DD."
          continue
        fi
        ;;
      esac

      if [[ "$isPK" == "PK" ]]; then
        if tail -n +2 "${DB_ROOT}/${CURRENT_DB}/${tableName}.db" | cut -d'|' -f$((currentCol + 1)) | grep -qx "$val"; then
          print_error "Primary Key '$val' already exists."
          continue
        fi
      fi

      rowData+="$val|"
      break
    done
    currentCol=$((currentCol + 1))
  done

  echo "${rowData%|}" >>"${DB_ROOT}/${CURRENT_DB}/${tableName}.db"
  print_success "Record inserted successfully into '$tableName'."
}

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
  count=$(awk -F'|' -v col="$col" -v val="$val" '
      function trim(s){ gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s); return s }
      BEGIN{ c=0; lcval=tolower(val) }
      NR==1{
        if (col ~ /^[0-9]+$/) {
          idx = col
          if (idx < 1 || idx > NF) { print "-1"; exit }
        } else {
          for (i=1;i<=NF;i++) { if (tolower(trim($i))==tolower(col)) { idx=i; break } }
          if (!idx) { print "-1"; exit }
        }
        next
      }
      {
        f = trim($idx)
        if (tolower(f) == lcval) c++
      }
      END{ print c }
    ' "$dbfile")

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
  awk -F'|' -v col="$col" -v val="$val" -v tmp="$tmp" '
      function trim(s){ gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s); return s }
      BEGIN{ lcval=tolower(val) }
      NR==1{
        if (col ~ /^[0-9]+$/) {
          idx = col
          if (idx < 1 || idx > NF) exit 2
        } else {
          for (i=1;i<=NF;i++) { if (tolower(trim($i))==tolower(col)) { idx=i; break } }
          if (!idx) exit 2
        }
        print $0 > tmp
        next
      }
      {
        f = trim($idx)
        if (tolower(f) != lcval) print $0 > tmp
      }
    ' "$dbfile"
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
