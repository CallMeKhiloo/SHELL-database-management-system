# 🗄️ Bash Shell Script DBMS — 7-Day Project Plan

> **Team:** Developer Khalil · Developer Giza  
> **Duration:** 7 Days  
> **Stack:** Bash (POSIX-compatible), CLI, Filesystem-based Storage  
> **Standards:** Modular scripting, error handling, portability, input validation

---

## 📐 Project Architecture Overview

```
dbms/
├── main.sh                  # Entry point — Main Menu
├── lib/
│   ├── utils.sh             # Shared utilities (colors, prompts, validators)
│   ├── db_manager.sh        # DB-level operations (create, list, drop, connect)
│   └── table_manager.sh     # Table-level operations (CRUD)
├── databases/               # Auto-generated; each DB = a sub-directory
│   └── <db_name>/
│       └── <table_name>.db  # Each table = a flat file (CSV-like)
│       └── <table_name>.meta # Schema definition (columns, types, PK)
└── docs/
    └── README.md
```

---

## 👥 Role Summary

|Role|Developer|Core Ownership|
|---|---|---|
|**Lead Architect / DB Engine**|Khalil|Core engine, DB manager, schema & validation logic|
|**Table Operations / UX**|Giza|Table CRUD, display formatting, menus & integration|

---

## 📅 Day-by-Day Plan

---

### ✅ Day 1 — Project Setup & Architecture Design

> **Milestone:** Shared codebase initialized, conventions agreed upon, scaffolding complete

| #   | Khalil                                                                                                                                             | Giza                                                                                                                  |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Initialize the Git repository; define branching strategy (`main`, `dev`, feature branches)                                                         | Set up local dev environment; clone the repo and verify Bash version compatibility                                    |
| 2   | Design the overall directory structure (`lib/`, `databases/`, `docs/`) and document it                                                             | Draft the full UI/UX flow diagram for both Main Menu and Database Menu (ASCII or draw.io)                             |
| 3   | Write `utils.sh`: define color constants (`RED`, `GREEN`, `CYAN`), `print_header()`, `print_success()`, `print_error()`, `print_warning()` helpers | Write the skeleton of `main.sh` with a `while true` loop and `case` statement for Main Menu (stubs only)              |
| 4   | Define the **file format spec** for `.meta` (schema) files: column names, data types (`INT`, `STR`, `DATE`), and primary key marker                | Define the **file format spec** for `.db` (data) files: delimiter choice (`\|`), row structure, header row convention |
| 5   | Document coding standards in `docs/README.md`: naming conventions, indentation (2-space), quoting rules, `set -euo pipefail` usage                 | Review Khalil's standards doc; add UX conventions (menu numbering, back/exit options, prompt styles)                  |

**End-of-Day Sync:** Both developers review and sign off on architecture + file formats before any code is written.

---

### ✅ Day 2 — Database-Level Operations (Khalil) + Main Menu Shell (Giza)

> **Milestone:** Main Menu is navigable; Create/List/Drop Database fully functional

|#|Khalil|Giza|
|---|---|---|
|1|Implement `create_database()` in `db_manager.sh`: validate DB name (alphanumeric + underscore only), check for duplicates, `mkdir` under `databases/`|Complete `main.sh` Main Menu loop: render numbered menu, read user input, call stub functions, handle invalid input gracefully|
|2|Implement `list_databases()`: scan `databases/` directory, display as a formatted numbered list; handle empty state ("No databases found")|Implement the `connect_to_database()` dispatcher in `main.sh`: prompt user to pick from listed DBs, validate selection, transition to DB Menu|
|3|Implement `drop_database()`: list DBs, prompt selection, add **confirmation prompt** ("Are you sure? [y/N]"), `rm -rf` with error handling|Implement the Database Menu loop in a new function `db_menu()` inside `main.sh`: render menu items for table operations (stubs), handle back/exit|
|4|Add `source utils.sh` to `db_manager.sh`; use color helpers in all output; ensure all functions `return 0` on success and `return 1` on failure|Wire Main Menu stubs to `db_manager.sh` functions by sourcing it in `main.sh`; test Create/List/Drop end-to-end|
|5|Write unit-level manual test cases for DB operations in `docs/test_cases.md`|Verify DB Menu renders correctly after connecting; test back navigation returns to Main Menu cleanly|

---

### ✅ Day 3 — Table Creation & Schema Engine (Khalil) + List/Drop Table (Giza)

> **Milestone:** Tables can be created with typed columns and a primary key, listed, and dropped

|#|Khalil|Giza|
|---|---|---|
|1|Implement `create_table()` in `table_manager.sh`: prompt for table name, validate (no spaces/special chars, no duplicate within DB)|Implement `list_tables()`: scan the active DB directory for `.meta` files, display table names in a formatted list; handle empty state|
|2|Inside `create_table()`: loop to collect column definitions — prompt for column name, then data type (`1. INT 2. STR 3. DATE`); store until user types `done`|Implement `drop_table()`: list tables, prompt selection, confirm with `[y/N]`, delete both `.meta` and `.db` files|
|3|Inside `create_table()`: prompt "Which column is the Primary Key?" — validate that the chosen column exists in the defined list|Add `source table_manager.sh` to `main.sh`; wire List Tables and Drop Table to the DB Menu|
|4|Write the `.meta` file from the collected schema: format `COL_NAME:TYPE:PK` per line (e.g., `id:INT:PK`, `name:STR:`, `dob:DATE:`)|Create the empty `.db` file with a header row derived from the `.meta` column names (pipe-delimited)|
|5|Write a `load_schema()` helper in `utils.sh` that reads a `.meta` file and returns column names, types, and PK column as arrays for reuse by all operations|Test full Create → List → Drop flow; verify `.meta` and `.db` files are created and removed correctly|

---

### ✅ Day 4 — Insert & Validation Engine (Khalil) + Select Display (Giza)

> **Milestone:** Data can be inserted with full type/PK validation and displayed in formatted output

|#|Khalil|Giza|
|---|---|---|
|1|Implement `insert_into_table()`: list tables, prompt selection, call `load_schema()` to get column definitions|Implement `select_from_table()`: list tables, prompt selection, read `.db` file line by line|
|2|Inside `insert_into_table()`: loop through each column, prompt for value, call type validator for each (`validate_int()`, `validate_str()`, `validate_date()`)|Inside `select_from_table()`: implement `print_table_formatted()` in `utils.sh` — dynamic column-width calculation, pipe-separated header, separator line (`---`), then data rows|
|3|Implement PK uniqueness check in `insert_into_table()`: extract PK column index from schema, scan `.db` file to ensure no existing row has the same PK value|Add optional "filter" to `select_from_table()`: after displaying, prompt "Filter by column? [y/N]"; if yes, prompt column name + value, re-display matching rows only|
|4|Write the validated row to the `.db` file as a pipe-delimited line; print success message with the inserted row|Handle edge case: table is empty (only header row) — display "Table is empty" message instead of a blank output|
|5|Write validation functions (`validate_int`, `validate_date` using regex) in `utils.sh` as shared helpers|Test Insert → Select round-trip: insert 3–5 rows with mixed types, verify display formatting is aligned and readable|

---

### ✅ Day 5 — Delete & Update Operations (Khalil) + Full Integration (Giza)

> **Milestone:** All 7 table operations functional; full app integrated end-to-end

|#|Khalil|Giza|
|---|---|---|
|1|Implement `delete_from_table()`: list tables, prompt selection, display current rows with row numbers|Perform **full integration testing**: navigate every menu path (Main Menu → Connect → all table ops → Back → Drop DB)|
|2|Inside `delete_from_table()`: prompt "Enter PK value to delete", find matching row, display it, confirm `[y/N]`, rewrite `.db` excluding that row using a `tmp` file + `mv`|Identify and log all bugs found during integration into `docs/bug_log.md` (bug ID, description, steps to reproduce)|
|3|Implement `update_table()`: list tables, prompt selection, prompt for PK value of the row to update, display matching row|Wire any remaining stubs in DB Menu to their implementations; ensure `source` paths are relative and portable (`$(dirname "$0")`)|
|4|Inside `update_table()`: loop through each column offering to update it — show current value, prompt new value (or Enter to skip), run type validation on new value|Add global `trap` in `main.sh` to catch `Ctrl+C` (SIGINT) and exit gracefully with a farewell message|
|5|Rewrite `.db` file with updated row using tmp file pattern; confirm success with before/after display|Run edge case tests: empty DB list, connecting to empty DB, inserting duplicate PK, invalid type input — verify all error messages are clear|

---

### ✅ Day 6 — Bonus Features + Error Hardening + Code Review

> **Milestone:** Bonus SQL parser attempted; all error handling hardened; peer code review done

|#|Khalil|Giza|
|---|---|---|
|1|**Bonus:** Implement a basic SQL parser in `sql_parser.sh` — use `grep`/`sed`/`awk` to parse and route simple commands: `CREATE TABLE`, `DROP TABLE`, `INSERT INTO`, `SELECT * FROM`, `DELETE FROM`, `UPDATE...SET`|**Bonus:** Add an option in the Main Menu: "Run SQL Command" — prompt for a single SQL string, pass to `sql_parser.sh`, display result|
|2|Add SQL support for `SELECT * FROM <table> WHERE <col> = <val>` — extract condition, filter `.db` rows with `awk`|Improve `print_table_formatted()` to handle long string values gracefully (truncate at N chars with `...`)|
|3|Harden all file operations: wrap every `mkdir`, `rm`, `mv`, `cp` in conditionals with meaningful error messages; never assume a path exists|Harden all user input loops: ensure every `read` prompt has a `-r` flag; prevent empty input from being accepted where a value is required|
|4|Add `set -euo pipefail` to the top of every script file; audit all scripts for unquoted variables and fix them|Conduct a **peer code review** of Khalil's `db_manager.sh` and `table_manager.sh` — review for logic correctness, readability, and standard compliance|
|5|Conduct a **peer code review** of Giza's `main.sh`, `utils.sh`, and display functions — verify menu flows, formatting, and input handling|Merge all feature branches into `dev`; resolve any merge conflicts; do a final smoke test of the entire application|

---

### ✅ Day 7 — Documentation, Final Testing & Delivery

> **Milestone:** Project delivered with full documentation, passing all test cases

|#|Khalil|Giza|
|---|---|---|
|1|Write **Technical Documentation** in `docs/README.md`: architecture overview, file format specs, how to run, dependencies, known limitations|Write **User Manual** section in `docs/README.md`: step-by-step usage guide with screenshots (terminal captures) of each menu and operation|
|2|Document all functions in `db_manager.sh` and `table_manager.sh` with inline comments: purpose, parameters, return codes|Document all functions in `main.sh` and `utils.sh` with inline comments; document the SQL bonus parser syntax supported|
|3|Write and execute the **Final Test Suite** (documented in `docs/test_cases.md`): create 2 DBs, 3 tables each, insert 10 rows, select with filter, update 2 rows, delete 1 row, drop a table, drop a DB|Execute the **Final Test Suite** independently on a fresh environment (different machine or clean directory) — log pass/fail results|
|4|Fix any bugs uncovered during final testing; ensure the app runs correctly from a clean clone (no pre-existing `databases/` directory)|Fix any formatting or UX issues uncovered; verify all success/error messages are consistent in tone and color|
|5|Merge `dev` into `main`; tag the release `v1.0.0`; write `CHANGELOG.md` summarizing what was built each day|Final demo run-through: record or document a complete walkthrough session; confirm delivery package is complete|

---

## 🏁 Milestones Summary

|Milestone|Day|Description|
|---|---|---|
|🏗️ **Project Kickoff**|Day 1|Repo initialized, architecture finalized, file formats agreed|
|🗄️ **Database Engine Live**|Day 2|Create / List / Connect / Drop Database working|
|📋 **Schema Engine Live**|Day 3|Create / List / Drop Table with typed columns and PK|
|📥 **Data I/O Live**|Day 4|Insert (with validation) and Select (with formatting) working|
|⚙️ **Full CRUD Live**|Day 5|Delete and Update complete; full app integrated end-to-end|
|🌟 **Bonus + Hardened**|Day 6|SQL parser added; all error handling hardened; code reviewed|
|🚀 **Delivered**|Day 7|Fully documented, tested, and tagged `v1.0.0`|

---

## 🧱 Technical Standards Reference

|Standard|Implementation|
|---|---|
|**Modularity**|Each concern in its own `lib/*.sh` file; sourced as needed|
|**Error Handling**|`set -euo pipefail` in all scripts; all operations check exit codes|
|**Portability**|POSIX-compatible syntax; use `$(...)` not backticks; `#!/usr/bin/env bash` shebang|
|**Input Validation**|Every user input validated before use; reject empty, wrong-type, or duplicate values|
|**Atomic File Writes**|All file modifications use temp file + `mv` pattern to prevent corruption|
|**Quoting**|All variables quoted (`"$var"`) to handle spaces in names|
|**PK Enforcement**|PK uniqueness checked on every insert; PK used as row identifier in delete/update|
|**Schema Integrity**|`.meta` file is the single source of truth; always loaded before any table operation|

---

## 🔗 Key Dependencies Between Developers

```
Khalil                              Giza
──────                              ────
utils.sh (Day 1) ──────────────────► used by main.sh (Day 1)
db_manager.sh (Day 2) ─────────────► wired in main.sh (Day 2)
load_schema() in utils.sh (Day 3) ─► used in insert/select (Day 4)
validate_*() in utils.sh (Day 4) ──► used in update (Day 5)
sql_parser.sh (Day 6) ─────────────► called from main.sh bonus menu (Day 6)
```

> **Rule:** Khalil completes shared utilities before Giza needs them.  
> **Rule:** Giza completes menu shells before Khalil's functions are wired in.  
> **Daily Sync:** 15-minute standup at start of each day to unblock dependencies.

---

_Plan version 1.0 — Generated for Khalil & Giza | Bash DBMS Sprint_