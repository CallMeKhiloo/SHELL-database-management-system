#!/usr/bin/env bash

display_main_menu() {
  clear

  echo "===== Main Menu ====="
  echo "1) Create Database"
  echo "2) List Databases"
  echo "3) Connect To Database"
  echo "4) Drop Database"
  echo "0) Exit"

  read -r -p "Choose option: " option

  while [[ ! "$option" =~ ^[0-9]+$ ]] || [[ "$option" -lt 0 ]] || [[ "$option" -gt 4 ]]; do
    print_error "Invalid option"
    read -r -p "Try again: " option
  done

  clear

  return "$option"
}

display_db_menu() {
  clear

  echo "==== Database: ${CURRENT_DB} ===="
  echo "1) Create Table"
  echo "2) List Tables"
  echo "3) Drop Table"
  echo "4) Select From Table"
  echo "5) Insert Into Table"
  echo "6) Update Table"
  echo "7) Delete From Table"
  echo "0) Back to Main Menu"

  read -r -p "Choose option: " option

  while [[ ! "$option" =~ ^[0-9]+$ ]] || [[ "$option" -lt 0 ]] || [[ "$option" -gt 7 ]]; do
    print_error "Invalid option"
    read -r -p "Try again: " option
  done

  clear

  return "$option"
}
