#!/usr/bin/env bash

# $0 is the path to the script from where you executed it and dirname will extract the path without the script name
PROJECT_ROOT="$(dirname "$0")"
source "${PROJECT_ROOT}/lib/displayMenu.sh"
source "${PROJECT_ROOT}/lib/utils.sh"
source "${PROJECT_ROOT}/lib/db_manager.sh"
source "${PROJECT_ROOT}/lib/table_manager.sh"

mkdir -p "${DB_ROOT}"

db_menu() {
  while true; do
    display_db_menu

    option=$?
    case "$option" in
    1) create_table ;;
    2) list_tables ;;
    3) drop_table ;;
    4) select_from_table ;;
    5) insert_into_table ;;
    6) update_table ;;
    7) delete_from_table ;;
    0) return 0 ;;
    *) print_error "Invalid option" ;;
    esac

    echo
    read -r -p "Press Enter to continue!"
  done
}

main() {
  while true; do
    display_main_menu

    option=$?
    case "$option" in
    1) create_database ;;
    2) list_databases ;;
    3)
      if connect_to_database; then
        db_menu
        continue
      fi
      ;;
    4) drop_database ;;
    0)
      print_header "Goodbye"
      exit 0
      ;;
    *) print_error "Invalid option" ;;
    esac

    echo
    read -r -p "Press Enter to continue!"
  done
}

main
