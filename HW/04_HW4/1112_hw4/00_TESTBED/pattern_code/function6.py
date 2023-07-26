with open('../pattern2_data/pattern2.dat', 'r') as f:
    datas = [line.strip() for line in f.readlines()]

data_no_line = [''.join(data.split('_')) for data in datas]
round_data = [data_no_line[i:i+8] for i in range(0, len(datas), 8)]

# print(round_data)
Low = '6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
High = 'AFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
answer = []
for i in round_data:
    int_list = [int(x, 16) for x in i]
    for j in int_list:
        if j < int(High, 16) and j > int(Low, 16):
            answer.append("%x" % j)


# print(answer)
with open('../pattern2_data/f6.dat', 'w') as f:
    for item in answer:
        f.write(str(item) + '\n')