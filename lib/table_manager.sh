#!/usr/bin/env bash

list_tables() {
  print_header "Tables in Database: $CURRENT_DB"

  local tables=$(ls "${DB_ROOT}/${CURRENT_DB}"/*.meta 2>/dev/null)

  if [[ -z "$tables" ]]; then
    print_error "No tables found in this database."
    return 0
  fi

  for table in $tables; do # here $tables is unquoted so we can iterate over each file
    echo "- $(basename "$table" .meta)"
  done
}

create_table() {
  local tableName colName colType isPK pkSelected="false" schema=""
  read -r -p "Enter the table name: " tableName

  if ! validate_name "$tableName"; then
    print_error "Invalid table name. Use only letters, numbers and underscores."
    return 1
  fi

  if [[ -f "$(dirname "$0")/DBs/$CURRENT_DB/$tableName.meta" ]]; then
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
        INT|STR|DATE) colType=$type; break ;;
        *) print_error "Invalid selection. Please choose 1, 2, or 3." ;;
      esac
    done

    if [[ "$pkSelected" == "false" ]]; then
      if confirm_prompt "Set '$colName' as Primary Key?"; then
        isPK="PK"
        pkSelected="true"
      else
        isPK=""
      fi
    else
      isPK=""
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

  echo -ne "$schema" > "$(dirname "$0")/DBs/$CURRENT_DB/$tableName.meta"
  local header=$(echo "$schema" | tr ',' '\n' | cut -d: -f1 | paste -sd '|' -)
  echo "$header" > "$(dirname "$0")/DBs/$CURRENT_DB/$tableName.db"

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
  else
    print_header "Operation cancelled."
    return 1
  fi
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
    IFS=':' read -r colName colType isPK <<< "$col" # IFS is the internal field separator

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
        if tail -n +2 "${DB_ROOT}/${CURRENT_DB}/${tableName}.db" | cut -d'|' -f$((currentCol+1)) | grep -qx "$val"; then
          print_error "Primary Key '$val' already exists."; continue
        fi
      fi
      
      rowData+="$val|"
      break
    done
    currentCol=$((currentCol + 1))
  done

  echo "${rowData%|}" >> "${DB_ROOT}/${CURRENT_DB}/${tableName}.db"
  print_success "Record inserted successfully into '$tableName'."
}