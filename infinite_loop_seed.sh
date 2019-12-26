#!/usr/bin/env bash
for i in $(seq 1 10);
do seed=$(( (RANDOM % 10000) + 1 ));
python ./GGNNChemModel.py --random_seed $seed --thresholds 0.5 | tee logs/infinite_loop/seeds/corenodes/SVDetector_"$i".log;
done