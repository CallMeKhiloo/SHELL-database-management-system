#!/usr/bin/awk -f
# Expects variables passed via -v: col (filter column name or index), val (filter value)
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

BEGIN {
    FS = "\\|"
    count = 0
    lcval = tolower(val)
    error = 0
}

NR == 1 {
    if (col ~ /^[0-9]+$/) {
        idx = col

        if (idx < 1 || idx > NF) {
            print "-1"
            error = 1
            exit
        }
    }
    else {
        for (i = 1; i <= NF; i++) {
            if (tolower(trim($i)) == tolower(col)) {
                idx = i
                break
            }
        }

        if (!idx) {
            print "-1"
            error = 1
            exit
        }
    }

    next
}

{
    f = trim($idx)

    if (tolower(f) == lcval) count++
}

END {
    if (error == 0) { print count }
}
