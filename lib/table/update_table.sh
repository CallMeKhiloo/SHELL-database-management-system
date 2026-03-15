#!/usr/bin/env bash

update_table() {
  local tableName pkValue lineNum
  read -r -p "Enter table name: " tableName

  local dbFile="${DB_ROOT}/${CURRENT_DB}/${tableName}.db"
  if [[ ! -f "$dbFile" ]]; then
    print_error "Table not found."
    return 1
  fi

  read -r -p "Enter Primary Key value to update: " pkValue
  # gets the first column(pk), gets the line number and matches only whole word then extracts the line number
  lineNum=$(cut -d'|' -f1 "$dbFile" | grep -nw "$pkValue" | cut -d: -f1)

  if [[ -z "$lineNum" || "$lineNum" -eq 1 ]]; then
    print_error "Record with PK '$pkValue' not found."
    return 1
  fi

  mapfile -t schema < <(load_schema "$tableName")

  if [[ ${#schema[@]} -eq 0 ]]; then
    print_error "Table '$tableName' does not exist or has no schema."
    return 1
  fi

  local newRow=""
  local currentCol=0
  for col in "${schema[@]}"; do
    IFS=':' read -r colName colType isPK <<<"$col"

    while true; do
      read -r -p "Enter NEW value for $colName ($colType): " val

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

      if [[ "$isPK" == "PK" && "$val" != "$pkValue" ]]; then
        if tail -n +2 "$dbFile" | cut -d'|' -f$((currentCol + 1)) | grep -qx "$val"; then
          print_error "New PK '$val' already exists."
          continue
        fi
      fi

      newRow+="$val|"
      break
    done
    currentCol=$((currentCol + 1))
  done

  newRow="${newRow%|}"
  sed -i "${lineNum}c\\${newRow}" "$dbFile" # c for change, it replaces the whole line with the new row
  print_success "Record with PK '$pkValue' updated successfully."
}
