import os
import re
import time
import numpy as np

# Boolean condition expression:
var_op_bool = ['!', '~', '**', '*', '!=', '<', '>', '<=', '>=', '==', '<<', '>>', '||', '&&']

# Assignment expressions
var_op_assign = ['|=', '=', '^=', '&=', '<<=', '>>=', '+=', '-=', '*=', '/=', '%=', '++', '--']


"""
block.timestamp is used for solidity smart contract
GetTimestamp() is used for vntchain smart contract
"""


# split all functions of contracts
def split_function(filepath):
    function_list = []
    f = open(filepath, 'r', encoding='utf-8')
    lines = f.readlines()
    f.close()
    flag = -1

    for line in lines:
        text = line.strip()
        if len(text) > 0 and text != "\n":
            if text.split()[0] == "function" or text.split()[0] == "function()":
                function_list.append([text])
                flag += 1
            elif len(function_list) > 0 and ("function" in function_list[flag][0]):
                function_list[flag].append(text)

    return function_list


# Position the call.value to generate the graph
def generate_graph(filepath):
    allFunctionList = split_function(filepath)  # Store all functions
    timeStampList = []  # Store all W functions that call call.value
    cFunctionList = []  # Store a single C function that calls a W function
    CFunctionLists = []  # Store all C functions that call W function
    withdrawNameList = []  # Store the W function name that calls block.timestamp
    otherFunctionList = []  # Store functions other than W functions
    node_list = []  # Store all the points
    edge_list = []  # Store edge and edge features
    node_feature_list = []  # Store nodes feature
    params = []  # Store the parameters of the W functions
    param = []
    key_count = 0  # Number of core nodes S and W
    c_count = 0  # Number of core nodes C

    # ======================================================================
    # ---------------------------  Handle nodes  ---------------------------
    # ======================================================================

    # Store other functions without W functions (with block.timestamp)
    for i in range(len(allFunctionList)):
        flag = 0
        for j in range(len(allFunctionList[i])):
            text = allFunctionList[i][j]
            if 'block.timestamp' in text:
                flag += 1
        if flag == 0:
            otherFunctionList.append(allFunctionList[i])

    # Traverse all functions, find the block.timestamp keyword, store the S and W nodes
    for i in range(len(allFunctionList)):
        for j in range(len(allFunctionList[i])):
            text = allFunctionList[i][j]
            if 'block.timestamp' in text and "=" in text:
                node_list.append("S")
                node_list.append("W" + str(key_count))
                timeStampList.append([allFunctionList[i], "S", "W" + str(key_count)])

                # For example: function transfer(address _to, uint _value, bytes _data, string _custom_fallback)
                # get function name (transfer)
                tmp = re.compile(r'\b([_A-Za-z]\w*)\b(?:(?=\s*\w+\()|(?!\s*\w+))')
                result_withdraw = tmp.findall(allFunctionList[i][0])  # get the function name of current W node
                withdrawNameTmp = result_withdraw[1]
                if withdrawNameTmp == "payable":
                    withdrawName = "FALLBACK"
                else:
                    withdrawName = withdrawNameTmp + "("
                withdrawNameList.append(["W" + str(key_count), withdrawName])

                # get the params of the selected function
                ss = allFunctionList[i][0]
                pp = re.compile(r'[(](.*?)[)]', re.S)
                result = re.findall(pp, ss)
                result_params = result[0].split(",")
                for n in range(len(result_params)):
                    param.append(result_params[n].strip().split(" ")[-1])
                params.append([param, "S", "W" + str(key_count)])

                # add the node and feature
                node_feature_list.append(
                    ["S", "S", ["W" + str(key_count)], 3])
                node_feature_list.append(
                    ["W" + str(key_count), "W" + str(key_count), [], 2])

                key_count += 1

    if key_count == 0:
        print("Currently, there is no key word block.timestamp")
        node_feature_list.append(["S", "S", ["NULL"], 0])
        node_feature_list.append(["W0", "W0", ["NULL"], 0])
        node_feature_list.append(["C0", "C0", ["NULL"], 0])
    else:
        # Traverse all functions and find the C function nodes that calls the W function
        # (determine the function call by matching the number of arguments)
        for k in range(len(withdrawNameList)):
            w_key = withdrawNameList[k][0]
            w_name = withdrawNameList[k][1]
            for i in range(len(otherFunctionList)):
                if len(otherFunctionList[i]) > 2:
                    for j in range(1, len(otherFunctionList[i])):
                        text = otherFunctionList[i][j]
                        if w_name in text:
                            p = re.compile(r'[(](.*?)[)]', re.S)
                            result = re.findall(p, text)
                            result_params = result[0].split(",")

                            if len(result_params) == len(params[k][0]):
                                cFunctionList += otherFunctionList[i]
                                CFunctionLists.append(
                                    [w_key, w_name, "C" + str(c_count), otherFunctionList[i]])
                                node_list.append("C" + str(c_count))

                                for n in range(len(node_feature_list)):
                                    if w_key in node_feature_list[n][0]:
                                        node_feature_list[n][2].append("C" + str(c_count))

                                node_feature_list.append(
                                    ["C" + str(c_count), "C" + str(c_count), ["NULL"], 1])

                                edge_list.append(["C" + str(c_count), w_key, "C" + str(c_count), 1, 'FW'])

                                c_count += 1
                                break

        if c_count == 0:
            print("There is no C node")
            node_list.append("C0")
            node_feature_list.append(["C0", "C0", ["NULL"], 0])
            for n in range(len(node_feature_list)):
                if "W" in node_feature_list[n][0]:
                    node_feature_list[n][2] = ["NULL"]

        # ======================================================================
        # ---------------------------  Handle edge  ----------------------------
        # ======================================================================

        # (1) W -> S (include: W -> VAR, VAR -> S, S -> VAR)
        for i in range(len(timeStampList)):
            flag = 0
            varCount = 0
            var_time = ""
            for j in range(len(timeStampList[i][0])):
                text = timeStampList[i][0][j]

                if 'block.timestamp' in text:
                    tmp_sent = timeStampList[i][0][j]
                    var_time = tmp_sent.split("=")[0]
                    if "return" in text:
                        edge_list.append(
                            [timeStampList[i][2], "VAR" + str(varCount), timeStampList[i][2], 2,
                             'RE'])
                        edge_list.append(
                            ["VAR" + str(varCount), timeStampList[i][1], "VAR" + str(varCount), 3,
                             'RE'])
                        node_feature_list.append(
                            ["VAR" + str(varCount), "VAR" + str(varCount), timeStampList[i][2], 2, 'ASSIGN'])
                        varCount += 1
                    else:
                        edge_list.append(
                            [timeStampList[i][2], "VAR" + str(varCount), timeStampList[i][2], 2,
                             'FW'])
                        edge_list.append(
                            ["VAR" + str(varCount), timeStampList[i][1], timeStampList[i][2], 3,
                             'FW'])
                        node_feature_list.append(
                            ["VAR" + str(varCount), "VAR" + str(varCount), timeStampList[i][2], 3, 'ASSIGN'])
                        varCount += 1
                    flag += 1

                if flag != 0 and var_time in text:
                    edge_list.append(
                        [timeStampList[i][1], "VAR" + str(varCount), timeStampList[i][2], 4, 'FW'])
                    node_feature_list.append(
                        ["VAR" + str(varCount), "VAR" + str(varCount), timeStampList[i][2], 3, 'DANGER'])
                    varCount += 1
                    break

    # Handling some duplicate elements, the filter leaves a unique
    edge_list = list(set([tuple(t) for t in edge_list]))
    edge_list = [list(v) for v in edge_list]
    node_feature_list_new = []
    [node_feature_list_new.append(i) for i in node_feature_list if not i in node_feature_list_new]
    # node_feature_list = list(set([tuple(t) for t in node_feature_list]))
    # node_feature_list = [list(v) for v in node_feature_list]
    # node_list = list(set(node_list))

    return node_feature_list_new, edge_list


def printResult(file, node_feature, edge_feature):
    main_point = ['S', 'W0', 'W1', 'W2', 'W3', 'W4', 'C0', 'C1', 'C2', 'C3', 'C4']

    for i in range(len(node_feature)):
        if node_feature[i][0] in main_point:
            for j in range(0, len(node_feature[i][2]), 2):
                if j + 1 < len(node_feature[i][2]):
                    tmp = node_feature[i][2][j] + "," + node_feature[i][2][j + 1]
                elif len(node_feature[i][2]) == 1:
                    tmp = node_feature[i][2][j]

            node_feature[i][2] = tmp

    # nodeOutPath = "../../data/reentrancy/graph_data/nodes_12/" + file
    # edgeOutPath = "../../data/reentrancy/graph_data/edges_12/" + file

    nodeOutPath = "../../tmp/node/" + file
    edgeOutPath = "../../tmp/edge/" + file

    f_node = open(nodeOutPath, 'a')
    for i in range(len(node_feature)):
        result = " ".join(np.array(node_feature[i]))
        f_node.write(result + '\n')
    f_node.close()

    f_edge = open(edgeOutPath, 'a')
    for i in range(len(edge_feature)):
        result = " ".join(np.array(edge_feature[i]))
        print(result)
        f_edge.write(result + '\n')
    f_edge.close()


if __name__ == "__main__":
    test_contract = "../../data/block_timestamp/solidity_contract/20888.sol"
    node_feature, edge_feature = generate_graph(test_contract)
    node_feature = sorted(node_feature, key=lambda x: (x[0]))
    edge_feature = sorted(edge_feature, key=lambda x: (x[2], x[3]))
    print("node_feature", node_feature)
    print("edge_feature", edge_feature)
    # printResult("20888.sol", node_feature, edge_feature)

    # inputFileDir = "../../data/reentrancy/contracts/"
    # dirs = os.listdir(inputFileDir)
    # start_time = time.time()
    # for file in dirs:
    #     inputFilePath = inputFileDir + file
    #     node_feature, edge_feature = generate_graph(inputFilePath)
    #     node_feature = sorted(node_feature, key=lambda x: (x[0]))
    #     edge_feature = sorted(edge_feature, key=lambda x: (x[2], x[3]))
    #     printResult(file, node_feature, edge_feature)
    #
    # end_time = time.time()
    # print(end_time - start_time)
