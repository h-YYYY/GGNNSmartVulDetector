from random import sample

raw_file_corenodes = "./tools/infinite_loop/result_tuned/Infinite_Loop_AutoExtract_corenodes_1467.json"
raw_data_corenodes = open(raw_file_corenodes, 'r')
lines_corenodes = raw_data_corenodes.readlines()

raw_file_fullnodes = "./tools/infinite_loop/result_tuned/Infinite_Loop_AutoExtract_fullnodes.json"
raw_data_fullnodes = open(raw_file_fullnodes, 'r')
lines_fullnodes = raw_data_fullnodes.readlines()
valid_idx = sample(range(1, len(lines_corenodes) - 1), int(len(lines_corenodes) * 0.2))

print("loading train/validation split")

train_out_fullnodes = "train_data/infinite_loop/train_fullnodes.json"
valid_out_fullnodes = "train_data/infinite_loop/valid_fullnodes.json"

train_out_corenodes = "train_data/infinite_loop/train_corenodes.json"
valid_out_corenodes = "train_data/infinite_loop/valid_corenodes.json"

train_fullnodes = open(train_out_fullnodes, 'a')
valid_fullnodes = open(valid_out_fullnodes, 'a')

train_corenodes = open(train_out_corenodes, 'a')
valid_corenodes = open(valid_out_corenodes, 'a')

for i in range(len(lines_corenodes)):
    if i not in valid_idx:
        train_fullnodes.write(lines_fullnodes[i])
        train_corenodes.write(lines_corenodes[i])
    else:
        valid_fullnodes.write(lines_fullnodes[i])
        valid_corenodes.write(lines_corenodes[i])
print('split finished')
