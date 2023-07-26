with open('../pattern2_data/pattern2.dat', 'r') as f:
    datas = [line.strip() for line in f.readlines()]

data_no_line = [''.join(data.split('_')) for data in datas]
round_data = [data_no_line[i:i+8] for i in range(0, len(datas), 8)]

answer = []
int_list = [int(x, 16) for x in round_data[0]]
# print(int_list)
max_fileter = max(int_list)
answer.append("%x" % max_fileter)
# print("%x" % max_fileter)
for i in round_data[1:]:
    int_list = [int(x, 16) for x in i]
    for j in int_list:
        if j > max_fileter:
            max_fileter = j
            answer.append("%x" % j)

# print(answer)
with open('../pattern2_data/f8.dat', 'w') as f:
    for item in answer:
        f.write(str(item) + '\n')