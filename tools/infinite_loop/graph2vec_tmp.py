import os
import json
import numpy as np
from infinite_loop.vec2onehot_tmp import vec2onehot

"""
S, W, C features: Node features + Edge features + Var features;
Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
"""

dict_FRE = {"NULL": 0, "void": 1, "uint": 2, "int": 3, "uint8": 4, "uint16": 5, "uint32": 6, "uint64": 7, "uint128": 8,
            "uint256": 9, "bool": 10, "string": 11, "address": 12, "fallback": 13}

dict_NodeName = {"NULL": 0, "FALLBACK": 1, "FUN1": 2, "FUN2": 3, "FUN3": 4, "FUN4": 5, "FUN5": 6, "FUN6": 7, "FUN7": 8,
                 "FUN8": 9, "VAR0": 10, "VAR1": 11, "VAR2": 12, "VAR3": 13, "VAR4": 14, "VAR5": 15, "Contract": 16}

dict_VarOpName = {"NULL": 0, "BOOL": 1, "ASSIGN": 2}

dict_VarFunName = {"NULL": 0, "INNFUN": 1, "FOR": 2, "WHILE": 3}

dict_EdgeOpName = {"NULL": 0, "FW": 1, "IF": 2, "GB": 3, "GN": 4, "WHILE": 5, "FOR": 6, "RE": 7, "AH": 8, "RG": 9,
                   "RH": 10, "IT": 11}

dict_NodeOpName = {"NULL": 0, "CALL": 1, "INNCALL": 2, "SELFCALL": 3, "FALLCALL": 4}

dict_InfiniteLoopFlag = {"NULL": 0, "INNLIMIT": 1, "NORM": 2, "OVERLIMIT": 3, "ABNORM": 4}

node_convert = {"FUN1": 0, "FUN2": 1, "FUN3": 2, "FUN4": 3, "FUN5": 4, "FUN6": 5, "FUN7": 6, "FUN8": 7, "FALLBACK": 8,
                "Contract": 9, "VAR0": "VAR0", "VAR1": "VAR1", "VAR2": "VAR2", "VAR3": "VAR3", "VAR4": "VAR4",
                "VAR5": "VAR5",}

v2o = vec2onehot()  # create the one-bot dicts


# extract the features of each nodes from input file #
def extract_node_features(nodeFile):
    nodeNum = 0
    node_list = []
    node_attribute_list = []

    f = open(nodeFile, encoding="utf-8")
    lines = f.readlines()
    f.close()

    for line in lines:
        node = list(map(str, line.split()))
        verExist = False
        for i in range(0, len(node_list)):
            if node[0] == node_list[i]:
                verExist = True
            else:
                continue
        if verExist is False:
            node_list.append(node[0])
            nodeNum += 1
        node_attribute_list.append(node)

    return nodeNum, node_list, node_attribute_list


# elimination procedure for sub_graph start here #
def elimination_node(node_attribute_list):
    extra_var_list = []  # extract var with low priority
    for i in range(0, len(node_attribute_list)):
        if i + 1 < len(node_attribute_list):
            if node_attribute_list[i][0] == node_attribute_list[i + 1][0]:
                loc1 = int(node_attribute_list[i][3])  # relative location
                op1 = node_attribute_list[i][4]  # operation
                loc2 = int(node_attribute_list[i + 1][3])
                op2 = node_attribute_list[i + 1][4]
                if loc2 - loc1 == 1:
                    op1_index = dict_VarOpName[op1]
                    op2_index = dict_VarOpName[op2]
                    # extract nodes attribute based on priority
                    if op1_index < op2_index:
                        extra_var_list.append(node_attribute_list.pop(i))
                    else:
                        extra_var_list.append(node_attribute_list.pop(i + 1))
    return node_attribute_list, extra_var_list


def embedding_node(node_attribute_list):
    # embedding each nodes after elimination #
    node_encode = []
    var_encode = []
    node_embedding = []
    var_embedding = []
    main_point = ['FUN1', 'FUN2', 'FUN3', 'FUN4', 'FUN5', 'FUN6', 'FUN7', 'FUN8', 'FALLBACK']

    for j in range(0, len(node_attribute_list)):
        v = node_attribute_list[j][0]
        if v in main_point:
            vf0 = node_attribute_list[j][0]
            vf1 = dict_NodeName[node_attribute_list[j][0]]
            vfm1 = v2o.node2vecEmbedding(node_attribute_list[j][0])
            vf2 = dict_FRE[node_attribute_list[j][1]]
            vfm2 = v2o.nodeAC2vecEmbedding(node_attribute_list[j][1])
            result = node_attribute_list[j][2].split(",")
            for call_vec in range(len(result)):
                if call_vec + 1 < len(result):
                    tmp_vf = str(dict_NodeName[result[call_vec]]) + "," + str(dict_NodeName[result[call_vec + 1]])
                    tmp_vfm = np.array(list(v2o.node2vecEmbedding(result[call_vec]))) ^ np.array(
                        list(v2o.node2vecEmbedding(result[call_vec + 1])))
                elif len(result) == 1:
                    tmp_vf = dict_NodeName[result[call_vec]]
                    tmp_vfm = v2o.node2vecEmbedding(result[call_vec])
            vf3 = tmp_vf
            vfm3 = tmp_vfm
            vf4 = int(node_attribute_list[j][3])
            vfm4 = v2o.sn2vecEmbedding(node_attribute_list[j][3])
            vf5 = int(node_attribute_list[j][4])
            vfm5 = v2o.sn2vecEmbedding(node_attribute_list[j][4])
            vf6 = dict_NodeOpName[node_attribute_list[j][5]]
            vfm6 = v2o.nodeOP2vecEmbedding(node_attribute_list[j][5])
            vf7 = dict_InfiniteLoopFlag[node_attribute_list[j][6]]
            vfm7 = v2o.infiniteLoopFlag2vecEmbedding(node_attribute_list[j][6])
            nodeEmbedding = vfm1.tolist() + vfm2.tolist() + vfm3.tolist() + vfm4.tolist() + vfm5.tolist() + vfm6.tolist() + vfm7.tolist()
            node_embedding.append([vf0, np.array(nodeEmbedding)])
            temp = [vf1, vf2, vf3, vf4, vf5, vf6, vf7]
            node_encode.append([vf0, temp])
        else:
            vf0 = node_attribute_list[j][0]
            vf1 = dict_NodeName[node_attribute_list[j][0]]
            vfm1 = v2o.node2vecEmbedding(node_attribute_list[j][0])
            vf2 = dict_NodeName[node_attribute_list[j][1]]
            vfm2 = v2o.node2vecEmbedding(node_attribute_list[j][1])
            vf3 = int(node_attribute_list[j][2])
            vfm3 = v2o.sn2vecEmbedding(node_attribute_list[j][2])
            vf4 = dict_VarFunName[node_attribute_list[j][3]]
            vfm4 = v2o.varFun2vecEmbedding(node_attribute_list[j][3])
            vf5 = dict_VarOpName[node_attribute_list[j][4]]
            vfm5 = v2o.varOP2vecEmbedding(node_attribute_list[j][4])
            varEmbedding = vfm1.tolist() + vfm2.tolist() + vfm3.tolist() + vfm4.tolist() + vfm5.tolist()
            var_embedding.append([vf0, np.array(varEmbedding)])
            temp = [vf1, vf2, vf3, vf4, vf5]
            var_encode.append([vf0, temp])

    node_embedding_length = len(node_embedding[0][1])
    vec = np.zeros(node_embedding_length, dtype=int)
    for i in range(len(var_embedding)):
        vec[0:len(np.array(var_embedding[i][1]))] = np.array(var_embedding[i][1])
        var_embedding[i][1] = vec

    return node_encode, var_encode, node_embedding, var_embedding, node_embedding_length


def elimination_edge(edgeFile):
    # eliminate edges #
    edge_list = []  # all edges
    extra_edge_list = []  # eliminated edges

    f = open(edgeFile, encoding="utf-8")
    lines = f.readlines()
    f.close()

    for line in lines:
        edge = list(map(str, line.split()))
        edge_list.append(edge)

    # The ablation of multiple edges between two nodes, taking the edges with the edge_operation priority
    for k in range(0, len(edge_list)):
        if k + 1 < len(edge_list):
            start1 = edge_list[k][0]  # start nodes
            end1 = edge_list[k][1]  # end nodes
            op1 = edge_list[k][4]
            start2 = edge_list[k + 1][0]
            end2 = edge_list[k + 1][1]
            op2 = edge_list[k + 1][4]
            if start1 == start2 and end1 == end2:
                op1_index = dict_EdgeOpName[op1]
                op2_index = dict_EdgeOpName[op2]
                # extract edges attribute based on priority
                if op1_index < op2_index:
                    extra_edge_list.append(edge_list.pop(k))
                else:
                    extra_edge_list.append(edge_list.pop(k + 1))

    return edge_list, extra_edge_list


def embedding_edge(edge_list):
    # extract & embedding the features of each edges from input file #
    edge_encode = []
    edge_embedding = []

    for k in range(len(edge_list)):
        start = edge_list[k][0]  # start nodes
        end = edge_list[k][1]  # end nodes
        a, b, c, d = edge_list[k][2], edge_list[k][3], edge_list[k][4], edge_list[k][5]  # origin info

        ef1 = dict_NodeName[a]
        ef2 = int(b)
        ef3 = dict_EdgeOpName[c]
        ef4 = dict_InfiniteLoopFlag[d]

        ef_temp = [ef1, ef2, ef3, ef4]
        edge_encode.append([start, end, ef_temp])

        efm1 = v2o.node2vecEmbedding(a)
        efm2 = v2o.sn2vecEmbedding(b)
        efm3 = v2o.edgeOP2vecEmbedding(c)
        efm4 = v2o.infiniteLoopFlag2vecEmbedding(d)

        efm_temp = efm1.tolist() + efm2.tolist() + efm3.tolist() + efm4.tolist()
        edge_embedding.append([start, end, np.array(efm_temp)])

    return edge_encode, edge_embedding


def construct_vec(node_list, node_embedding, var_embedding, edge_embedding, edge_encode, node_embedding_length):
    # Vec: Node self property + Incoming Var + Outgoing Var + Incoming Edge + Outgoing Edge
    print("Start constructing nodes vector...")
    var_in_node = []
    var_in = []
    var_out_node = []
    var_out = []
    edge_in_node = []
    edge_in = []
    edge_out_node = []
    edge_out = []
    node_vec = []

    main_point = ['FALLBACK', 'FUN1', 'FUN2', 'FUN3', 'FUN4', 'FUN5', 'FUN6', 'FUN7', 'FUN8']
    node_embeddings_dim = 250
    edge_vec_length = 44
    var_vec_length = node_embedding_length

    if len(var_embedding) > 0:
        for k in range(len(edge_embedding)):
            if edge_embedding[k][0] in main_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][1]):
                        # record the out edges feature and out var feature of one nodes
                        var_out.append([edge_embedding[k][0], var_embedding[i][1]])
                        edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            if edge_embedding[k][1] in main_point:
                for i in range(len(var_embedding)):
                    if str(var_embedding[i][0]) == str(edge_embedding[k][0]):
                        # record the in edges feature and in var feature of one nodes
                        var_in.append([edge_embedding[k][1], var_embedding[i][1]])
                        edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])
    else:
        for k in range(len(edge_embedding)):
            if edge_embedding[k][0] in main_point:
                edge_out.append([edge_embedding[k][0], edge_embedding[k][2]])
            if edge_embedding[k][1] in main_point:
                edge_in.append([edge_embedding[k][1], edge_embedding[k][2]])

    for i in range(len(var_in)):
        var_in_node.append(var_in[i][0])
    for i in range(len(var_out)):
        var_out_node.append(var_out[i][0])
    for i in range(len(edge_in)):
        edge_in_node.append(edge_in[i][0])
    for i in range(len(edge_out)):
        edge_out_node.append(edge_out[i][0])

    for i in range(len(node_list)):
        if node_list[i] not in var_in_node:
            var_in.append([node_list[i], np.zeros(var_vec_length, dtype=int)])
        if node_list[i] not in var_out_node:
            var_out.append([node_list[i], np.zeros(var_vec_length, dtype=int)])
        if node_list[i] not in edge_out_node:
            edge_out.append([node_list[i], np.zeros(edge_vec_length, dtype=int)])
        if node_list[i] not in edge_in_node:
            edge_in.append([node_list[i], np.zeros(edge_vec_length, dtype=int)])

    varIn_dict = dict(var_in)
    varOut_dict = dict(var_out)
    edgeIn_dict = dict(edge_in)
    edgeOut_dict = dict(edge_out)

    for i in range(len(node_embedding)):
        vec = np.zeros(node_embeddings_dim)
        if node_embedding[i][0] in main_point:
            node_feature = node_embedding[i][1].tolist() + np.array(varIn_dict[node_embedding[i][0]]).tolist() + \
                           np.array(varOut_dict[node_embedding[i][0]]).tolist()
            vec[0:len(np.array(node_feature))] = np.array(node_feature)
            node_vec.append([node_embedding[i][0], vec])

    for i in range(len(node_vec)):
        node_vec[i][1].astype(np.float64)
        node_vec[i][1] = node_vec[i][1].tolist()

    if len(node_vec) == 1:
        node_vec.append(['FUN2', np.array(np.zeros(node_embeddings_dim)).astype(np.float64).tolist()])
        node_vec.append(['FUN3', np.array(np.zeros(node_embeddings_dim)).astype(np.float64).tolist()])
    elif len(node_vec) == 2:
        node_vec.append(['FUN3', np.array(np.zeros(node_embeddings_dim)).astype(np.float64).tolist()])

    print("Node Vec:")
    for i in range(len(node_vec)):
        node_vec[i][0] = node_convert[node_vec[i][0]]
        print(node_vec[i][0], node_vec[i][1])

    for i in range(len(edge_embedding)):
        edge_embedding[i][2] = edge_embedding[i][2].tolist()

    # S0 -> 0, W0 -> 1, C0 -> 2
    if len(edge_encode) == 2:
        end = edge_encode[len(edge_encode) - 2][1]
        start = edge_encode[len(edge_encode) - 1][0]
        flag = edge_encode[len(edge_encode) - 1][1]
        if end == start and ('VAR' in flag):
            edge_encode[len(edge_encode) - 1][1] = edge_encode[len(edge_encode) - 2][0]

    if len(edge_encode) > 2:
        end1 = edge_encode[len(edge_encode) - 1][1]
        start2 = edge_encode[len(edge_encode) - 2][0]
        if end1 == start2 and ('VAR' in end1):
            edge_encode[len(edge_encode) - 1][1] = edge_encode[len(edge_encode) - 3][0]

    for i in range(len(edge_encode)):
        if i + 1 < len(edge_encode):
            start1 = edge_encode[i][0]
            end1 = edge_encode[i][1]
            start2 = edge_encode[i + 1][0]

            if end1 == start2 and ('VAR' in end1):
                edge_encode[i][1] = edge_encode[i + 1][1]
                edge_encode[i + 1][0] = edge_encode[i][0]

    print("Edge Vec:")
    for i in range(len(edge_encode)):
        edge_encode[i][0] = node_convert[edge_encode[i][0]]
        edge_encode[i][1] = node_convert[edge_encode[i][1]]
        print(edge_encode[i][0], edge_encode[i][1], edge_encode[i][2])

    graph_edge = []

    for i in range(len(edge_encode)):
        graph_edge.append([edge_encode[i][0], edge_encode[i][2][2], edge_encode[i][1]])

    print(graph_edge)

    return node_vec, graph_edge


if __name__ == "__main__":
    node = "../../data/infinite_loop/graph_data/nodes/function_call8.c"
    edge = "../../data/infinite_loop/graph_data/edges/function_call8.c"
    nodeNum, node_list, node_attribute_list = extract_node_features(node)
    node_attribute_list, extra_var_list = elimination_node(node_attribute_list)
    node_encode, var_encode, node_embedding, var_embedding, node_embedding_length = embedding_node(node_attribute_list)

    for k in range(len(node_embedding)):
        print(node_embedding[k])
    for k in range(len(var_embedding)):
        print(var_embedding[k])

    edge_list, extra_edge_list = elimination_edge(edge)
    edge_encode, edge_embedding = embedding_edge(edge_list)
    node_vec = construct_vec(node_list, node_embedding, var_embedding, edge_embedding, edge_encode, node_embedding_length)


    v_path = "../../data/infinite_loop/graph_data/nodes/"
    e_path = "../../data/infinite_loop/graph_data/edges/"

    corenodes_output_tmp = open('./result/Infinite_Loop_AutoExtract_corenodes.json', 'w')
    fullnodes_ouptput_tmp = open('./result/Infinite_Loop_AutoExtract_fullnodes.json', 'w')
    corenodes_ouptput_gcn = open('./result/Infinite_Loop_AutoExtract_corenodes_gcn.txt', 'a')
    fullnodes_ouptput_gcn = open('./result/Infinite_Loop_AutoExtract_fullnodes_gcn.txt', 'a')
    contract_name = open("./infinite_loop_contract_name.txt")  # contracts list
    contract_label = open("./infinite_loop_contract_label.txt")  # contracts label
    names = contract_name.readline().strip(" ")
    labels = contract_label.readline()

    while names:
        node = os.path.join(v_path, names.strip('\n'))
        edge = os.path.join(e_path, names.strip('\n'))
        print(node)

        nodeNum, node_list, node_attribute_list = extract_node_features(node)
        node_attribute_list, extra_var_list = elimination_node(node_attribute_list)
        node_encode, var_encode, node_embedding, var_embedding, node_embedding_length = embedding_node(node_attribute_list)

        edge_list, extra_edge_list = elimination_edge(edge)
        edge_encode, edge_embedding = embedding_edge(edge_list)
        node_vec, graph_edge = construct_vec(node_list, node_embedding, var_embedding, edge_embedding, edge_encode, node_embedding_length)

        node_embedding = sorted(node_embedding, key=lambda x: (x[0]))
        var_embedding = sorted(var_embedding, key=lambda x: (x[0]))
        fullnodes_ouptput_gcn.write(names)
        corenodes_ouptput_gcn.write(names)

        for k in range(len(node_embedding)):
            node_embedding[k][1].astype(np.float64)
            node_embedding[k][1] = node_embedding[k][1].tolist()
            fullnodes_ouptput_gcn.write(str(node_embedding[k][0]) + ":" + str(node_embedding[k][1]) + '\n')
        for k in range(len(var_embedding)):
            var_embedding[k][1].astype(np.float64)
            var_embedding[k][1] = var_embedding[k][1].tolist()
            fullnodes_ouptput_gcn.write(str(var_embedding[k][0]) + ":" + str(var_embedding[k][1]) + '\n')
        for k in range(len(node_vec)):
            corenodes_ouptput_gcn.write(str(node_vec[k][0]) + ":" + str(node_vec[k][1]) + '\n')

        corenodes_feature_list = []
        for i in range(len(node_vec)):
            corenodes_feature_list.append(node_vec[i][1])

        fullnodes_feature_list = []
        for i in range(len(node_embedding)):
            fullnodes_feature_list.append(node_embedding[i][1])
        for i in range(len(var_embedding)):
            fullnodes_feature_list.append(var_embedding[i][1])

        edge_dict = {
            "graph": graph_edge
        }

        node_feature_dict = {
            "node_features": corenodes_feature_list,
        }

        graph_dict = ({
            "targets": labels.strip('\n'),
            "graph": graph_edge,  # graph_edge,
            "node_features": corenodes_feature_list,  # corenodes_feature_list
        })

        fullnode_graph_dict = ({
            "targets": labels.strip('\n'),
            "graph": graph_edge,  # graph_edge,
            "node_features": fullnodes_feature_list,  # corenodes_feature_list
        })

        result = json.dumps(graph_dict)
        fullnodes_result = json.dumps(fullnode_graph_dict)

        corenodes_output_tmp.write(result + "," + "\n")
        fullnodes_ouptput_tmp.write(fullnodes_result + "," + "\n")
        names = contract_name.readline()
        labels = contract_label.readline()

    fullnodes_ouptput_gcn.close()
    corenodes_ouptput_gcn.close()
    corenodes_output_tmp.close()
    fullnodes_ouptput_tmp.close()

