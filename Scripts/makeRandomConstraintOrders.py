import os
import random
import sys

file = sys.argv[1]
out = sys.argv[2]
num = int(sys.argv[3])  # Number of random orders

try:
    f = open(file, 'r')
except IOError:
    print("Unknown file: "+file)
    sys.exit()

lines = list()
for l in f:
    lines.append(l.strip())

f.close()

for i in range(num):
    # Changing the order of the 15 constraints
    sels = random.sample(lines, 15)
    out_i = os.path.join(out, "Rep_"+str(i))
    os.mkdir(out_i)
    for j in range(1, 15):
        with open(os.path.join(out_i, "constraints_" + str(j) + ".Rev"), 'w') as fout:
            k = 1
            for l in sels:
                fout.write(l+"\n")
                if k == j:
                    break
                k = k+1
