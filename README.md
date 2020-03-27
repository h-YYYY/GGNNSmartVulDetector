# GGNNSmartVulDetector![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GGNNSmartVulDetector.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GGNNSmartVulDetector.svg?color=blue&style=plastic) ![License](https://img.shields.io/github/license/Messi-Q/GGNNSmartVulDetector.svg?color=blue&style=plastic)

This repo is a python implementation of smart contract vulnerability detection based on graph neural network (i.e, GGNN). 
In this research work, we focus on detecting two kinds of smart contract vulnerabilities (i.e., reentrancy and infinite loop), 
which are not only the most significant threat to contract security but also challenging to precisely identify. 
All of the infinite loop types we concerned are implemented by Class C/C++ of [VNT](https://github.com/vntchain/go-vnt), 
while the smart contract for reentrancy wirrten by Solidity, a.k.a [Ethereum](https://etherscan.io/) smart contract. 
Ethereum, a decentralized platform that runs smart contracts represented by Solidity. Ethereum is a decentralized blockchain 
platform that can build a broad scope of applications, while Ether is one kind of cryptocurrency used on this platform.
Vntchain, an open-source distributed value network that runs smart contracts represented by Class C/C++. 
Vntchain is a novel and evolutionary blockchain platform, which borrows the architecture mode from Ethereum and 
incorporates Delegate Proof of Stake (DPOS) and Byzantine Fault Tolerance (BFT) technologies for higher 
performance and security. 

Experiments are conducted on two real-world smart contract datasets, namely ESC (Ethereum Smart Contracts) and VSC (VNT chain Smart Contracts), which are collected from Ethereum and VNT Chain, respectively. The ESC dataset consists of 40,932 smart contracts from Ethereum, of which 1,671 contracts contain call.value invocations. This suggests that the call.value function is still widely in use, although it is susceptible to reentrancy vulnerabilities. The ESC smart contracts roughly contain 307, 396 functions in total, and the 1, 671 contracts with call.value invocations contain roughly 12,515 functions. The VSC dataset contains all the available 4, 170 smart contracts collected from the VNT Chain network, which overall contain 13, 761 functions.

## Requirements

#### Required Packages
* **python**3
* **TensorFlow**1.14.0
* **keras**2.2.4 with TensorFlow backend
* **sklearn** for model evaluation
* **docopt** as a command-line interface parser 
* **go-vnt** as a vntchain platform support
* **go-ethereum** as a ethereum platform support

Run the following script to install the required packages.
```shell
pip install --upgrade pip
pip install --upgrade tensorflow
pip install keras
pip install scikit-learn
pip install docopt
```

### Required Dataset
For each dataset, we randomly pick 20% contracts as the training set while the remainings are utilized for the testing set. In the comparison, metrics accuracy, recall, precision, and F1 score are all involved. In consideration of the distinct features of different platforms, experiments on reentrancy vulnerability and timestamp dependence vulnerability are conducted on the ESC dataset, while experiments on infinite loop vulnerability detection are conducted on the VSC dataset.

### Dataset
Ethereum smart contracts:  [Etherscan_contract](https://drive.google.com/open?id=1h9aFFSsL7mK4NmVJd4So7IJlFj9u0HRv)

Vntchain smart contacts: [Vntchain_contract](https://drive.google.com/open?id=1FTb__ERCOGNGM9dTeHLwAxBLw7X5Td4v)


### Data structure
All of the vnt smart contract source code and graph dataset in these folders in the following structure respectively.
```shell
${GGNNSmartVulDetector}
├── data
│   ├── infinite_loop
│   │   └── contract
│   │   └── graph_data
│   ├── block_timestamp
│   │   └── contract
│   │   └── graph_data
│   └── reentrancy
│       └── contract
│       └── graph_data
├── train_data
│   ├── infinite_loop
│   │   └── train_corenodes.json
│   │   └── train_fullnodes.json
│   │   └── vaild_corenodes.json
│   │   └── vaild_fullnodes.json
│   ├── block_timestamp
│   │   └── train_corenodes.json
│   │   └── train_fullnodes.json
│   │   └── vaild_corenodes.json
│   │   └── vaild_fullnodes.json
│   └── reentrancy
│       └── train_corenodes.json
│       └── train_fullnodes.json
│       └── vaild_corenodes.json
│       └── vaild_fullnodes.json
└── comparison
    ├── infinite_loop
    │   └── dropout
    │   └── model
    │   └── learning_rate
    │   └── roc
    ├── timestamp
    │   └── dropout
    │   └── model
    │   └── learning_rate
    │   └── roc
    └── reentrancy
        └── dropout
        └── model
        └── learning_rate
        └── roc
```


* `data/reentrancy/contract`:  This is the dataset for original smart contracts.
* `data/reentrancy/graph_data`: This is the dataset that it can be trained for our proposed TMP model. Among them, it includes the nodes and edges that are extracted by AutoExtractor.
* `graph_data/edge`: It includes all edges and edge attributes of each smart contract graph structure.
* `graph_data/node`: It includes all nodes and node attributes of each smart contract graph structure.
* `train_data/reentrancy/train_corenodes.json`: This is the feature vector of core points after feature ablation for training.
* `train_data/reentrancy/train_fullnodes.json`: This is the feature vector of full points without feature ablation for training.
* `comparison/reentrancy/dropout`: This is comparison for hyper-parameter dropout.
* `comparison/reentrancy/model`: This is comparison for hyper-parameter model layers.
* `comparison/reentrancy/learning_rate`: This is comparison for hyper-parameter learning rate.
* `comparison/reentrancy/roc`: This is comparison for hyper-parameter roc curves.


### Code Files
The tools and models are as follows:
```shell
${GGNNSmartVulDetector}
├── tools
│   ├── remove_comment.py
│   ├── construct_fragment.py
│   ├── AutoExtractGraph.py
│   └── graph2vec.py
├── AsyncGGNNChemModel.py
├── BasicChemModel.py
└── utils.py
```

`AsyncGGNNChemModel.py`
* Interface to project, uses functionality from other code files.
* Loads dataset, trains gcn model, passes to neural network, models evaluation.
* Specific implementation for GGNN model 

`AsyncGGNNChemModel.py`
* Basically model of GNN.
* Basicall hyper-parameters for GNN.

`utils.py`
* The general tools for adjusting the iteration of models, include make_network_params.

`AutoExtractGraph.py`
* All functions in the smart contract code are automatically split and stored.
* Find the relationships between functions.
* Extract all smart contracts source code into features of nodes and edges.

`graph2vec.py`
* Feature ablation.
* Converts graph into vectors.

**Note:** The graph structure automation extraction tool is being improved.

## Baselines
We implemented our TMP network with TensorFlow. We compared with the following competitive open-source smart contract vulnerability detection tools on the reentrancy detection task.

**Oyente**: A well-known symbolic verification tool for smart contract vulnerability detection, which performs symbolic execution on the CFG (control flow graph) to check vulnerable patterns.

**Mythril**: A security analysis method, which uses Concolic analysis, taint analysis and control flow checking to detect a variety of smart contract vulnerabilities.

**Smartcheck**: An extensible static analysis tool for discovering smart contract code vulnerabilities.

**Securify**: A formal-verification based tool for Ethereum smart contract bugs, which checks compliance and violation patterns to filter false positives.

**LSTM**: The most widely used recurrent neural network for processing sequential data. LSTM is short for long short term memory, which recurrently updates the cell state upon successively reading a frame in the sequence.

**GCN**: The graph convolutional network that implements layer-wise convolution on graph structured input using the graph Laplacian.


## Running project
* To run the program, use this command: python AsyncGGNNChemModel.py.
* Also, you can use specific hyper-parameters to train the model, which can be found in `AsyncGGNNChemModel.py` and `BasicChemModel.py`.

Examples:
```shell
python AsyncGGNNChemModel.py --random 9930 --thresholds 0.4
```

Using script：
Repeating 10 times for different seeds with `*_seed.sh`.
```shell
for i in $(seq 1 10);
do seed=$(( (RANDOM % 10000) + 1 ));
python ./AsyncGGNNChemModel.py --random_seed $seed --thresholds 0.4 | tee */SVDetector_"$i".log;
done
```
Repeating for different thresholds with `*_threshold.sh`.
```shell
for i in 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0;
do
python ./AsyncGGNNChemModel.py --random_seed 9930 --thresholds $i | tee */SVDetector_"$i".log;
done
```
Then, you can find the training results in the `logs`.


## References
1. VNT Document. [vnt-document](https://github.com/vntchain/vnt-documentation).
2. Graph classification with Graph Convolutional Networks in PyTorch. [graph_nn](https://github.com/bknyaz/graph_nn).
3. Smart contract vulnerability detection based on graph neural network (GCN). [GraphDeeSmartContract](https://github.com/Messi-Q/GraphDeeSmartContract).
4. Thomas N. Kipf, Max Welling, Semi-Supervised Classification with Graph Convolutional Networks, ICLR 2017. [GCN](https://arxiv.org/abs/1609.02907).
5. Li Y, Tarlow D, Brockschmidt M, et al. Gated graph sequence neural networks. ICLR, 2016. [GGNN](https://arxiv.org/abs/1511.05493)



