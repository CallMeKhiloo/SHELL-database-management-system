#!/usr/bin/awk -f
# Expects variables passed via -v: col (filter column name or index), val (filter value), tmp (tmp file to store not deleted data)
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

BEGIN {
    FS = "\\|"
    val = tolower(trim(val))
    col = tolower(trim(col))
}

# Check if column is name or index and store it as col_index
NR == 1 {
    if (col ~ /^[0-9]+$/) {
        col_index = int(col)

        if (col_index < 1 || col_index > NF) exit 1
    }
    else {
        for (i = 1; i <= NF; i++) {
            if (tolower(trim($i)) == col) {
                col_index = i
                break
            }
        }

        if (!col_index) exit 1
    }

    print $0 > tmp
    next
}

{
    if (tolower(trim($col_index)) != val) print $0 > tmp
}

END { close(tmp) }
