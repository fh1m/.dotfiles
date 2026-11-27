# Noninteractive Den commands need UTF-8 too. Qt otherwise prints a locale
# warning on stdout before its machine-readable IPC response.
# Preserve an explicitly selected locale; this is only the unset default.
export LANG="${LANG:-C.UTF-8}"
