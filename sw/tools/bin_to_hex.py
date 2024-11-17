import sys
import struct

if len(sys.argv) < 2:
    print("Missing input file")
    exit()

with open(sys.argv[1], "rb") as f:
    data = f.read()

    assert len(data) % 4 == 0

    words = []

    for i in range(0, len(data), 4):
        word = struct.unpack("<I", data[i : i + 4])[0]
        words.append(word)

    for i, b in enumerate(words):
        print(f"@{(i):08X} {b:08x}")
