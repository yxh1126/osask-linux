#!/usr/bin/env python3
"""
makefont.py - Convert hankaku.txt font source to binary font data

Replaces makefont.exe from the original Haribote OS build tools.

Input format (hankaku.txt):
    char 0x21
    ........
    .*..*...
    .*..*...
    ...
    (16 lines of 8 chars, '.' = 0, '*' = 1)

Output (hankaku.bin):
    4096 bytes = 256 characters x 16 bytes/char
    Each byte is a row of 8 pixels (MSB = leftmost pixel).

Usage: makefont.py input.txt output.bin
"""

import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: makefont.py <input.txt> <output.bin>", file=sys.stderr)
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]

    # 256 chars x 16 bytes = 4096 bytes
    font = bytearray(4096)

    with open(infile, 'r', encoding='shift_jis', errors='replace') as f:
        lines = f.readlines()

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        i += 1

        if not line:
            continue

        # Parse "char 0xNN" header
        if line.startswith('char '):
            parts = line.split()
            char_code = int(parts[1], 16)

            # Read next 16 lines as font rows
            for row in range(16):
                if i >= len(lines):
                    break
                rowline = lines[i].strip()
                i += 1

                # Convert 8 chars to a byte
                # '.' = 0, '*' = 1, MSB = leftmost
                byte = 0
                for col in range(8):
                    if col < len(rowline) and rowline[col] == '*':
                        byte |= (0x80 >> col)

                font[char_code * 16 + row] = byte

    with open(outfile, 'wb') as f:
        f.write(font)

    print(f"makefont: wrote {len(font)} bytes to {outfile}")


if __name__ == '__main__':
    main()
