with open('../pattern2_data/pattern2.dat', 'r') as f:
    datas = [line.strip() for line in f.readlines()]

data_no_line = [''.join(data.split('_')) for data in datas]
round_data = [data_no_line[i:i+8] for i in range(0, len(datas), 8)]
# print(round_data)
# answer = [max(round_data[i]) for i in range(len(round_data))]

answer = []

for one_round in round_data:
    big1 = 0
    big2 = 0
    for data in one_round:
        if data > big1:
            big2 = big1
            big1 = data
        elif data > big2:
            big2 = data
    answer.append(big1)
    answer.append(big2)

# print(answer)
with open('../pattern2_data/f3.dat', 'w') as f:
    for item in answer:
        f.write(str(item) + '\n')