#!/usr/bin/env bash

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

