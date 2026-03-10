#!/usr/bin/env bash

# $0 is the path to the script from where you executed it and dirname will extract the path without the script name
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/db_manager.sh"
source "$(dirname "$0")/lib/table_manager.sh"

mkdir -p "${DB_ROOT}"

db_menu() {
  while true; do
    echo
    echo "Database: ${CURRENT_DB}"
    echo "1) Create Table"
    echo "2) List Tables"
    echo "3) Drop Table"
    echo "4) Back to Main Menu"

    read -r -p "Choose option: " opt

    case "$opt" in
    1) create_table ;;
    2) list_tables ;;
    3) drop_table ;;
    4) return 0 ;;
    *) print_error "Invalid option" ;;
    esac
  done
}

main_menu() {
  while true; do
    echo
    echo "Main Menu"
    echo "1) Create Database"
    echo "2) List Databases"
    echo "3) Connect To Database"
    echo "4) Drop Database"
    echo "5) Exit"

    read -r -p "Choose option: " option

    case "$option" in
    1) create_database ;;
    2) list_databases ;;
    3)
      if connect_to_database; then
        db_menu
      fi
      ;;
    4) drop_database ;;
    5)
      print_header "Goodbye"
      exit 0
      ;;
    *) print_error "Invalid option" ;;
    esac
  done
}

main_menu
