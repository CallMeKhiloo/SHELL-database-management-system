#!/usr/bin/awk -f
# Expects variables passed via -v: fcol (filter column name or index), fval (filter value)

BEGIN { FS = "\\|"; OFS = " | " }

function trim(s) { gsub(/^[ \t\r\n]+/, "", s); gsub(/[ \t\r\n]+$/, "", s); return s }

NR==1 {
  nfields = NF
  for (i=1; i<=NF; i++) {
    hdr[i] = trim($i)
    hdr_lc[i] = tolower(hdr[i])
    w[i] = length(hdr[i])
  }
  next
}

{ rows[++r] = $0
  split($0, a, FS)
  for (i=1; i<=nfields; i++) {
    val = trim(a[i])
    if (length(val) > w[i]) w[i] = length(val)
  }
}

function print_table(arr, cnt, widths, i,k,a,val) {
  # Header
  for (i=1; i<=nfields; i++) {
    printf "%-*s", widths[i], hdr[i]
    if (i<nfields) printf OFS
  }
  print ""

  # Separator
  for (i=1; i<=nfields; i++) {
    for (j=1; j<=widths[i]; j++) printf "-"
    if (i<nfields) printf OFS
  }
  print ""

  # Rows
  for (k=1; k<=cnt; k++) {
    split(arr[k], a, FS)
    for (i=1; i<=nfields; i++) {
      val = trim(a[i])
      printf "%-*s", widths[i], val
      if (i<nfields) printf OFS
    }
    print ""
  }
}

END {
  if (r == 0) exit 2

  if (fcol == "") {
    print_table(rows, r, w)
    exit 0
  }

  fcol_trim = trim(fcol)
  fcol_lc = tolower(fcol_trim)
  fval_trim = trim(fval)
  fval_lc = tolower(fval_trim)

  idx = 0
  if (fcol_trim ~ /^[0-9]+$/) {
    idx = int(fcol_trim)
    if (idx < 1 || idx > nfields) exit 3
  } else {
    for (i=1; i<=nfields; i++) if (hdr_lc[i] == fcol_lc) { idx = i; break }
    if (idx == 0) exit 3
  }

  m = 0
  for (i=1; i<=nfields; i++) w2[i] = length(hdr[i])
  for (k=1; k<=r; k++) {
    split(rows[k], a, FS)
    val = trim(a[idx])
    if (tolower(val) == fval_lc) {
      matched[++m] = rows[k]
      for (i=1; i<=nfields; i++) {
        v = trim(a[i])
        if (length(v) > w2[i]) w2[i] = length(v)
      }
    }
  }
  if (m == 0) exit 4
  for (i=1; i<=nfields; i++) w[i] = w2[i]
  print_table(matched, m, w)
  exit 0
}

