import os,binascii

#print binascii.b2a_hex(os.urandom(16))
new_pattern_pre = []
new_pattern_aft = []
for i in range(96):
    new_pattern_pre.append(binascii.b2a_hex(os.urandom(16)))
# print(new_pattern)

for string in new_pattern_pre:
    new_string = '_'.join([string[i:i+2] for i in range(0, len(string), 2)])
    # print(new_string)
    new_pattern_aft.append(new_string)

with open('../pattern2_data/pattern2.dat', 'w') as f:
    for item in new_pattern_aft:
        f.write(str(item) + '\n')