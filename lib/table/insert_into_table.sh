#!/usr/bin/env bash

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

