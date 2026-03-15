#!/usr/bin/awk -f
# Expects variables passed via -v: col (filter column name or index), val (filter value)
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

function update_widths(row,   i, field_len, fields) {
    split(row, fields, FS)

    for (i = 1; i <= num_fields; i++) {
        field_len = length(trim(fields[i]))

        if (field_len > col_width[i]) col_width[i] = field_len
    }
}

function print_table(data, count,   i, j, fields) {
    if (count == 0) return

    for (i = 1; i <= num_fields; i++) {
        printf("%-*s", col_width[i], header_name[i])

        if (i < num_fields) printf(OFS)
    }

    print ""

    for (i = 1; i <= num_fields; i++) {
        for (j = 1; j <= col_width[i]; j++) printf("-")

        if (i < num_fields) printf(OFS)
    }

    print ""

    for (i = 1; i <= count; i++) {
        split(data[i], fields, FS)

        for (j = 1; j <= num_fields; j++) {
            printf("%-*s", col_width[j], trim(fields[j]))

            if (j < num_fields) printf(OFS)
        }

        print ""
    }
}

BEGIN {
    FS = "\\|"
    OFS = " | "
    val = tolower(trim(val))
    col = tolower(trim(col))
}

NR == 1 {
    num_fields = NF

    for (i = 1; i <= NF; i++) {
        header_name[i] = tolower(trim($i))
        col_width[i] = length(header_name[i])
    }

    if (col != "") {
        if (col ~ /^[0-9]+$/) {
            col_index = int(col)

            if (col_index < 1 || col_index > num_fields) exit 3
        }
        else {
            for (i = 1; i <= num_fields; i++)
            if (header_name[i] == col) {
                col_index = i
                break
            }

            if (col_index == 0) exit 3
        }
    }

    next
}

{
    total_rows++

    # col_index == 0 means no filter
    # col_index  > 0 means filter active
    if (col_index == 0 || tolower(trim($col_index)) == val) {
        result_count++
        result_data[result_count] = $0
        update_widths($0)
    }
}

END {
    if (total_rows == 0) exit 2

    if (result_count == 0) exit 4

    print_table(result_data, result_count)
}
