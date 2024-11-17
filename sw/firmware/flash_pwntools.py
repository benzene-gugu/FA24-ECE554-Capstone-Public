import serial
import sys
import time

import serial.tools

from pwn import *


def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i : i + n]


with open(sys.argv[2], "rb") as f:
    data = f.read()

addr = 32 * 1024 * 1024

chksum = 0
for i in range(len(data)):
    chksum += data[i]

chksum_byte = chksum.to_bytes(4, "big")

addr_bytes = addr.to_bytes(4, "big")

# size_bytes = (128).to_bytes(4, 'big')#len(data).to_bytes(4, 'big')
size_bytes = len(data).to_bytes(4, "big")

send_bytes = size_bytes + addr_bytes + data + chksum_byte
send_jump = b"j" + addr_bytes


# s = serial.Serial(sys.argv[1], 115200, timeout=3)
s = serialtube(sys.argv[1], 115200)
s.send(b"s")

echo = s.recv(1)
print(echo)

# for i, chunk in enumerate(chunks(send_bytes, 4)):
#     print("Sending chunk", i, "total:", len(send_bytes)/4)
#     s.write(chunk)
s.send(send_bytes)

check = s.recv(1)
print(check)

s.send(send_jump)
echo = s.recv(1)
print(echo)

s.interactive()
