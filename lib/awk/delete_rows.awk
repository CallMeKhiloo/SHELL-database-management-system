#!/usr/bin/awk -f
# Expects variables passed via -v: col (filter column name or index), val (filter value), tmp (tmp file to store not deleted data)
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

BEGIN { lcval = tolower(val) }

NR == 1 {
    if (col ~ /^[0-9]+$/) {
        idx = col

        if (idx < 1 || idx > NF) exit 2
    }
    else {
        for (i = 1; i <= NF; i++) {
            if (tolower(trim($i)) == tolower(col)) {
                idx = i
                break
            }
        }

        if (!idx) exit 2
    }

    print $0 > tmp
    next
}

{
    f = trim($idx)

    if (tolower(f) != lcval) print $0 > tmp
}
