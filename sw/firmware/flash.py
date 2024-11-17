import serial
import sys
import time


def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i : i + n]


with open(sys.argv[2], "rb") as f:
    data = f.read()
print("bin size:", len(data))
data = data + 3 * len(data) * (b"\0")

addr = 32 * 1024 * 1024

chksum = 0
for i in range(len(data)):
    chksum += data[i]

chksum_byte = chksum.to_bytes(4, "big")

addr_bytes = addr.to_bytes(4, "big")

# size_bytes = (128).to_bytes(4, 'big')#len(data).to_bytes(4, 'big')
size_bytes = len(data).to_bytes(4, "big")
print("actual sending size:", len(data))

send_bytes = size_bytes + addr_bytes + data + chksum_byte
send_jump = b"j" + addr_bytes


s = serial.Serial(sys.argv[1], 115200, timeout=3)
s.write(b"s")

echo = s.read()
print(echo)

# for i, chunk in enumerate(chunks(send_bytes, 4)):
#     print("Sending chunk", i, "total:", len(send_bytes)/4)
#     s.write(chunk)
s.write(send_bytes)

check = s.read()
print(check)

s.write(send_jump)
echo = s.read()
print(echo)
