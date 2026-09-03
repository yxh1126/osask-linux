#!/bin/bash
# nas-preprocess.sh - Strip nask-only directives and leading underscores from .nas files
# Usage: nas-preprocess.sh input.nas output.nas
#
# Strips:
#   [FORMAT "WCOFF"]      - nask COFF format directive
#   [INSTRSET "i486p"]    - nask instruction set directive
#   [FILE "..."]          - nask COFF file name directive
#
# Strips leading underscores from GLOBAL and EXTERN labels:
#   GLOBAL _io_hlt   ->  GLOBAL io_hlt
#   EXTERN _inthandler20  ->  EXTERN inthandler20
# This matches gcc's no-underscore ELF convention (nasm -f elf32).

set -e

IN="$1"
OUT="${2:-/dev/stdout}"

# 1. Remove nask-only directive lines
# 2. Strip leading underscores from GLOBAL/EXTERN label lists
sed \
  -e '/\[FORMAT "WCOFF"\]/d' \
  -e '/\[INSTRSET "i486p"\]/d' \
  -e '/\[FILE ".*"\]/d' \
  -e 's/^\([[:space:]]*GLOBAL[[:space:]]\+\)_/\1/g' \
  -e 's/^\([[:space:]]*EXTERN[[:space:]]\+\)_/\1/g' \
  -e 's/,\([[:space:]]*\)_\([a-zA-Z]\)/,\1\2/g' \
  "$IN" > "$OUT"
