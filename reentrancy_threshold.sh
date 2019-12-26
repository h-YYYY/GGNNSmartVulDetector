#!/usr/bin/env bash
for i in 0.0 0.02 0.05 0.08 0.1 0.12 0.15 0.18 0.2 0.22 0.25 0.28 0.3 0.32 0.35 0.38 0.4 0.42 0.45 0.48 0.5 0.52 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.78 0.8 0.82 0.85 0.88 0.9 0.92 0.95 0.98 1.0;
do
python ./GGNNChemModel.py --random_seed 9930 --thresholds $i | tee logs/reentrancy/thresholds/fullnodes/SVDetector_"$i".log;
done