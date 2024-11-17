import sys

if len(sys.argv) < 4:
    print("Missing args")
    exit()

pad_size = int(sys.argv[2])

data = None
with open(sys.argv[1], "rb") as f:
    data = f.read()

if len(data) > pad_size:
    print("Data bigger than pad size")
    exit()

with open(sys.argv[3], "wb") as f:
    data += b"\0" * (pad_size - len(data))
    f.write(data)
