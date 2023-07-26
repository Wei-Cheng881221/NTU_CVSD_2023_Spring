with open('../pattern2_data/pattern2.dat', 'r') as f:
    datas = [line.strip() for line in f.readlines()]

data_no_line = [''.join(data.split('_')) for data in datas]
round_data = [data_no_line[i:i+8] for i in range(0, len(datas), 8)]

answer = []
int_list = [int(x, 16) for x in round_data[0]]
# print(int_list)
min_fileter = min(int_list)
# print("%x" % min_fileter)
answer.append("%x" % min_fileter)
for i in round_data[1:]:
    int_list = [int(x, 16) for x in i]
    for j in int_list:
        if j < min_fileter:
            min_fileter = j
            answer.append("%x" % j)

# print(answer)
with open('../pattern2_data/f9.dat', 'w') as f:
    for item in answer:
        f.write(str(item) + '\n')