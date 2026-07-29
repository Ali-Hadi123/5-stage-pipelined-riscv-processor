#!/usr/bin/env python3
import sys

def bin_to_hex(bin_path, hex_path):
  with open(bin_path, "rb") as file_in:
    data = file_in.read()

  if len(data) % 4 != 0:                    #Ensures data is a multiple of 4 bytes to enable word allignment.
    data += b"\x00" * (4 - len(data) % 4)

  with open(hex_path, "w") as file_out:
    for i in range(0, len(data), 4):
      word_bytes = data[i:i+4]
      word = int.from_bytes(word_bytes, byteorder="little")
      out.write(f"{word:08x}\n")

  print(f"Wrote {len(data) // 4} words to {hex_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 bin_to_hex.py input.bin output.hex")
        sys.exit(1)
 
    bin_to_hex(sys.argv[1], sys.argv[2])
