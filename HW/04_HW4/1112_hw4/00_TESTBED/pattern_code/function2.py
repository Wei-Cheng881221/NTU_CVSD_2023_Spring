with open('../pattern2_data/pattern2.dat', 'r') as f:
    datas = [line.strip() for line in f.readlines()]

data_no_line = [''.join(data.split('_')) for data in datas]
round_data = [data_no_line[i:i+8] for i in range(0, len(datas), 8)]

answer = [min(round_data[i]) for i in range(len(round_data))]

# print(answer)
with open('../pattern2_data/f2.dat', 'w') as f:
    for item in answer:
        f.write(str(item) + '\n')