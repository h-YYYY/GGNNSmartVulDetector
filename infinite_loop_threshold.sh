#!/usr/bin/env bash
for threshold in 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0;
do
python ./GGNNChemModel.py --random_seed 9930 --thresholds $threshold | tee logs/infinite_loop/thresholds/corenodes/SVDetector_"$threshold".log;
done
