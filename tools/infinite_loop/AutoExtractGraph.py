import os
import re
import time
import numpy as np

# map user-defined variables to symbolic names(var)

# Boolean condition expression (VAR: )
var_op_bool = ['!', '~', '**', '*', '!=', '<', '>', '<=', '>=', '==', '<<', '>>', '||', '&&']

# Assignment expressions
var_op_assign = ['|=', '=', '^=', '&=', '<<=', '>>=', '+=', '-=', '*=', '/=', '%=', '++', '--']

# vntchain built-in functions (VAR: INNFUN)
built_in_functions = ["GetSender", "GetOrigin", "GetValue", "GetBalanceFromAddress", "GetContractAddress",
                      "GetBlockHash", "GetBlockNumber", "GetTimestamp", "GetBlockProduser", "SHA3", "Ecrecover",
                      "GetGas", "GetGasLimit", "SendFromContract", "TransferFromContract", "FromI64", "FromU64",
                      "ToI64", "ToU64", "Concat", "Equal", "PrintAddress", "PrintStr", "PrintUint64T", "PrintUint32T",
                      "PrintInt64T", "PrintInt32T", "PrintUint256T", "AddressFrom", "AddressToString", "U256From",
                      "U256ToString", "AddKeyInfo", "WriteWithPointer", "ReadWithPointer", "InitializeVariables",
                      "Pow", "U256FromU64", "U256FromI64", "U256_Add", "U256_Sub", "U256_Mul", "U256_Div", "U256_Mod",
                      "U256_Pow", "U256_Shl", "U256_Shr", "U256_And", "U256_Or", "U256_Xor", "U256_Cmp", "AddGas",
                      "U256SafeMul", "U256SafeDiv", "U256SafeSub", "U256SafeAdd", "EVENT", "PrintUint16T",
                      "PrintUint128T"]

# keywords of vnt; immutable set
keywords = frozenset({'int8', 'int16', 'int32', 'int64', 'int128', 'int256', 'uint8', 'uint16', 'uint32', 'uint64',
                      'uint128', 'uint256', 'void', 'bool', 'string', 'address', 'constructor', 'KEY', 'EVENT', 'break',
                      'case', 'catch', 'char', 'char16_t', 'char32_t', 'class', 'compl', 'const', 'const_cast',
                      'constexpr', 'continue', 'decltype', 'default', 'delete', 'do', 'double', 'dynamic_cast', 'else',
                      'enum', 'explicit', 'export', 'extern', 'false', 'final', 'float', 'for', 'friend', 'goto', 'if',
                      'inline', 'int', 'long', 'mutable', 'namespace', 'new', 'noexcept', 'not', 'not_eq', 'nullptr',
                      'operator', 'or', 'or_eq', 'override', 'private', 'protected', 'public', 'register', 'revert',
                      'reinterpret_cast', 'return', 'short', 'signed', 'sizeof', 'static', 'static_assert', 'assert',
                      'static_cast', 'struct', 'switch', 'template', 'this', 'thread_local', 'throw', 'true', 'try',
                      'typedef', 'typeid', 'typename', 'union', 'unsigned', 'using', 'virtual', 'volatile',
                      'wchar_t', 'while', 'xor', 'xor_eq', 'NULL', 'and'})

# function return type
function_return_list = ['int8', 'int16', 'int32', 'int64', 'int128', 'int256', 'uint8', 'uint16', 'uint32', 'uint64',
                        'uint128', 'uint256', 'void', 'bool', 'string', 'address', "$_()", "_()", "fallback"]

# define edges operations
edge_operations = ['return', 'assert', 'require', 'revert']

# define edges operation expression
dict_edgeOpName = {"NULL": 0, "FW": 1, "IF": 2, "GB": 3, "GN": 4, "WHILE": 5, "FOR": 6, "RE": 7, "AH": 8, "RG": 9,
                   "RH": 10, "IT": 11}

# define infinite loop flag (aims to "for" and "while")
dict_InfiniteLoopFlag = {"NULL": 0, "INNLIMIT": 1, "NORM": 2, "OVERLIMIT": 3, "ABNORM": 4}

# define the methods of function call
dict_NodeOpName = {"NULL": 0, "CALL": 1, "INNCALL": 2, "SELFCALL": 3, "FALLCALL": 4}

"""
time sequence: start function: 1; first edges: 2; all var nodes: 2; second edges: 3; end function: 3 
function call methods: CALL, INNCALL, MULCALL, SELFCALL, FALLBACK
define var nodes: If there is a built-in function, it is named var nodes 
VAR Node Feature: VAR0 FUN0 2 INNFUN ASSIGN / VAR0 FUN0 2 FOR ASSIGN / VAR0 FUN0 2 WHILE ASSIGN
"""

"""
int8 - [-128 : 127]
int16 - [-32768 : 32767]
int32 - [-2147483648 : 2147483647]
int64 - [-9223372036854775808 : 9223372036854775807]

uint8 - [0 : 255]
uint16 - [0 : 65535]
uint32 - [0 : 4294967295]
uint64 - [0 : 18446744073709551615]
"""


# split all functions of contracts
def split_function(filepath):
    function_list = []
    f = open(filepath, 'r', encoding="utf-8")
    lines = f.readlines()
    f.close()
    flag = -1

    for line in lines:
        count = 0
        text = line.rstrip()
        if len(text) > 0 and text != "\n":
            if "uint" in text.split()[0] and text.startswith("uint"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("uint" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "void" in text and text.startswith("void"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("void" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "bool" in text and text.startswith("bool"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("bool" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "string" in text and text.startswith("string"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("string" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "address" in text and text.startswith("address"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("address" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "$_()" in text and text.startswith("$_()"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("$_()" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue
            if "_()" in text and text.startswith("_()"):
                function_list.append([text])
                flag += 1
                continue
            elif len(function_list) > 0 and ("_()" in function_list[flag][0]):
                for types in function_return_list:
                    if text.startswith(types):
                        count += 1
                if count == 0:
                    function_list[flag].append(text)
                    continue

    return function_list


# function: get_key
def get_key(dictName, value):
    return [k for k, v in dictName.items() if v == value]


# Position the call.value to generate the graph
# inputFile: the specific path of smart contract
def generate_graph(inputFile):
    allFunctionList = split_function(inputFile)
    functionNameList = []  # Store all functions' name
    functionReTypeList = []  # Store all the function return types
    node_list = []  # Store all the points
    edge_list = []  # Store all the edges and edges features
    var_node_list = []  # store var nodes
    node_feature_list = []  # Store nodes feature
    var_feature_list = []  # Store var feature
    main_point = ['FUN1', 'FUN2', 'FUN3', 'FUN4', 'FUN5', 'FUN6', 'FUN7', 'FUN8', 'FALLBACK', 'Contract']
    var_point = ['VAR1', 'VAR2', 'VAR3', 'VAR4', 'VAR5', 'VAR6', 'VAR7', 'VAR8', 'VAR9']

    # Store all functions' name
    for i in range(len(allFunctionList)):
        tmp = re.compile(".*?(?=\\()")
        funTypeAndName = tmp.match(allFunctionList[i][0]).group()
        if funTypeAndName != "$_" and funTypeAndName != "_":
            result = funTypeAndName.split(" ")
            functionReTypeList.append(result[0])
            functionNameList.append(result[1])
        else:
            functionReTypeList.append("fallback")
            functionNameList.append(funTypeAndName)

    # label node_list
    for i in range(len(functionNameList)):
        if functionNameList[i] == "_" or functionNameList[i] == "$_":
            node_list.append("FALLBACK")
        else:
            node_list.append("FUN" + str(i + 1))

    # ======================================================================
    # ----------------------  Handle nodes and edges  ------------------------
    # ======================================================================
    for i in range(len(allFunctionList)):
        # regular expression to find variable name candidates
        varCount = 0  # number of var
        callCount = 0  # check if current function calls other function
        selfCallCount = 0  # check if function has a self call
        callerList = []  # store the function for calling
        currentProcessedFunctionName = functionNameList[i]  # current function name
        otherFunctionNameList = functionNameList[0:i] + functionNameList[i + 1:len(allFunctionList)]  # function names
        otherFunctionList = allFunctionList[0:i] + allFunctionList[i + 1:len(
            allFunctionList)]  # Store other functions without the being processed function
        otherNodeList = node_list[0:i] + node_list[i + 1:len(allFunctionList)]  # other nodes

        if functionNameList[i] != "_" and functionNameList[i] != "$_":
            node_feature_list.append([node_list[i], functionReTypeList[i]])

            # ======================================================================
            # ---------------------------  Handle nodes  ----------------------------
            # ======================================================================
            # handle current function called by other functions
            for j in range(len(otherFunctionList)):
                for k in range(len(otherFunctionList[j])):
                    text = otherFunctionList[j][k]
                    if currentProcessedFunctionName in text:
                        print("currentProcessedFunctionName is called by other function")
                        callerList.append(otherNodeList[j])
                        break

            var_tmp_index = 0
            called_function_tmp_index = 0
            var_flag = 0
            called_function_flag = 0
            # handle current function calling other functions(core nodes and var nodes)
            for n in range(1, len(allFunctionList[i])):
                text = allFunctionList[i][n]

                if currentProcessedFunctionName in text:
                    selfCallCount += 1

                for k in range(len(built_in_functions)):
                    if built_in_functions[k] in text:
                        varCount += 1
                        var_tmp_index = k
                        var_flag = n
                        break

                for m in range(len(otherFunctionNameList)):
                    if otherFunctionNameList[m] in text:
                        callCount += 1
                        called_function_tmp_index = m
                        called_function_flag = n
                        break

            # handle node_feature_list
            if len(callerList) > 0:
                node_feature_list[i].append(callerList)
                if callCount != 0 or varCount > 0:
                    node_feature_list[i].append('1')
                else:
                    node_feature_list[i].append('0')
                if varCount != 0:
                    node_feature_list[i].append("4")
                else:
                    node_feature_list[i].append("3")
                if selfCallCount != 0:
                    node_feature_list[i].append('SELFCALL')
                    node_feature_list[i].append('NULL')
                else:
                    node_feature_list[i].append('CALL')
                    node_feature_list[i].append('NULL')
            else:
                node_feature_list[i].append(['NULL'])
                if callCount != 0 or selfCallCount != 0 or varCount > 0:
                    node_feature_list[i].append('1')
                else:
                    node_feature_list[i].append('0')
                if selfCallCount != 0:
                    node_feature_list[i].append('1')
                    node_feature_list[i].append('SELFCALL')
                    node_feature_list[i].append('NULL')
                else:
                    node_feature_list[i].append('0')
                    node_feature_list[i].append('NULL')
                    node_feature_list[i].append('NULL')

            # ======================================================================
            # -------------------------  Handle edges and var  ---------------------
            # ======================================================================
            for n in range(1, len(allFunctionList[i])):
                text = allFunctionList[i][n]
                text_value = re.findall('[a-zA-Z0-9]+', text)

                if callCount != 0:
                    if varCount > 0:
                        if called_function_flag < var_flag:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                 'NULL'])
                            break

                        elif "for" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0].split(";")
                            result_value = re.sub("\D", "", result[1])

                            if "<" in result[1] and ("--" or "-=" in result[2]):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif ">" in result[1] and ("++" or "+=" in result[2]):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            # uint8: the max value is 255, uint16: the max value is 65535; the max value is 4294967295
                            elif "uint8" in result[0] and int(result_value) > 255:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint16" in result[0] and int(result_value) > 65535:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint32" in result[0] and int(result_value) > 4294967295:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif (result[0] == "" or " ") and (result[1] == "" or " ") and (result[2] == "" or " "):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR', 'INNLIMIT'])

                            edge_list.append(
                                ['VAR' + str(len(var_node_list)), otherNodeList[called_function_tmp_index],
                                 node_list[i], 3, 'FW', 'NULL'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'OVERLIMIT'
                            else:
                                node_feature_list[i][6] = 'INNLIMIT'

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 2, 'FOR', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 2, 'FOR', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 2, 'FOR', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break

                        elif "while" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0]

                            if "True" == result:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'WHILE',
                                     'ABNORM'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'WHILE',
                                     'NORM'])
                                infiniteloopflag += 1

                            edge_list.append(
                                ['VAR' + str(len(var_node_list)), otherNodeList[called_function_tmp_index],
                                 node_list[i], 3, 'FW', 'NULL'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'ABNORM'
                            else:
                                node_feature_list[i][6] = 'NORM'

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 2, 'WHILE', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 2, 'WHILE', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 2, 'WHILE', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break

                        elif built_in_functions[var_tmp_index] in text_value:
                            if "Assert" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'Ah', 'NULL'])

                            elif "Require" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RG', 'NULL'])

                            elif "Revert" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RH', 'NULL'])

                            elif "Return" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RE', 'NULL'])

                            elif "if" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'IF', 'NULL'])

                            else:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'FW', 'NULL'])

                            edge_list.append(
                                ['VAR' + str(len(var_node_list)), otherNodeList[called_function_tmp_index],
                                 node_list[i], 3, 'FW', 'NULL'])

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break
                    else:
                        if "for" in text_value:
                            infiniteloopflag = 0
                            if called_function_flag > n:
                                result = re.findall('[(](.*?)[)]', text)[0].split(";")
                                result_value = re.sub("\D", "", result[1])

                                if "<" in result[1] and ("--" or "-=" in result[2]):
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                elif ">" in result[1] and ("++" or "+=" in result[2]):
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                elif "uint8" in result[0] and int(result_value) > 255:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                elif "uint16" in result[0] and int(result_value) > 65535:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                elif "uint32" in result[0] and int(result_value) > 4294967295:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                elif (result[0] == "" or " ") and (result[1] == "" or " ") and (result[2] == "" or " "):
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'OVERLIMIT'])
                                    infiniteloopflag += 1
                                else:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FOR',
                                         'INNLIMIT'])
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'OVERLIMIT'
                            else:
                                node_feature_list[i][6] = 'INNLIMIT'

                            break

                        elif "while" in text_value:
                            infiniteloopflag = 0
                            if called_function_flag > n:
                                result = re.findall('[(](.*?)[)]', text)[0]

                                if "True" == result:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index],
                                         node_list[i], 2, 'WHILE', 'ABNORM'])
                                    infiniteloopflag += 1
                                else:
                                    edge_list.append(
                                        [node_list[i], otherNodeList[called_function_tmp_index],
                                         node_list[i], 2, 'WHILE', 'NORM'])
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'ABNORM'
                            else:
                                node_feature_list[i][6] = 'NORM'

                            break

                        elif "Assert" in text_value:
                            if called_function_flag > n:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'AH', 'NULL'])
                                break
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                        elif "Require" in text_value:
                            if called_function_flag > n:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RG', 'NULL'])
                                break
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                        elif "Revert" in text_value:
                            if called_function_flag > n:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RH', 'NULL'])
                                break
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                        elif "Return" in text_value:
                            if called_function_flag > n:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RE', 'NULL'])
                                break
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                        elif "if" in text_value:
                            if called_function_flag > n:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'IF', 'NULL'])
                                break
                            else:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                        else:
                            if n == len(allFunctionList[i]) - 1:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break

                else:
                    if varCount > 0:
                        if "for" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0].split(";")
                            result_value = re.sub("\D", "", result[1])

                            if "<" in result[1] and ("--" or "-=" in result[2]):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif ">" in result[1] and ("++" or "+=" in result[2]):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint8" in result[0] and int(result_value) > 255:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint16" in result[0] and int(result_value) > 65535:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint32" in result[0] and int(result_value) > 4294967295:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif (result[0] == "" or " ") and (result[1] == "" or " ") and (result[2] == "" or " "):
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR',
                                     'OVERLIMIT'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'FOR', 'INNLIMIT'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'OVERLIMIT'
                            else:
                                node_feature_list[i][6] = 'INNLIMIT'

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'FOR', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 3, 'FOR', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'FOR', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break

                        elif "while" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0]

                            if "True" == result:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'WHILE',
                                     'ABNORM'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], 'VAR' + str(len(var_node_list)), node_list[i], 2, 'WHILE',
                                     'NORM'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'ABNORM'
                            else:
                                node_feature_list[i][6] = 'NORM'

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'WHILE', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 3, 'WHILE', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'WHILE', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break

                        elif built_in_functions[var_tmp_index] in text_value:
                            if "Assert" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'AH', 'NULL'])

                            elif "Require" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RG', 'NULL'])

                            elif "Revert" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RH', 'NULL'])

                            elif "Return" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RE', 'NULL'])

                            elif "if" in text_value:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'IF', 'NULL'])

                            else:
                                edge_list.append(
                                    [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'FW', 'NULL'])

                            var_node = 0
                            var_bool_node = 0

                            for b in range(len(var_op_bool)):
                                if var_op_bool[b] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'BOOL'])
                                    var_bool_node += 1
                                    var_node += 1
                                    break

                            if var_bool_node == 0:
                                for a in range(len(var_op_assign)):
                                    if var_op_assign[a] in text:
                                        var_feature_list.append(
                                            ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'ASSIGN'])
                                        var_node += 1
                                        break

                            if var_node == 0:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'NULL'])

                            var_node_list.append('VAR' + str(len(var_node_list)))
                            break
                    else:
                        if "for" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0].split(";")
                            result_value = re.sub("\D", "", result[1])

                            if "<" in result[1] and ("--" or "-=" in result[2]):
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif ">" in result[1] and ("++" or "+=" in result[2]):
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint8" in result[0] and int(result_value) > 255:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint16" in result[0] and int(result_value) > 65535:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif "uint32" in result[0] and int(result_value) > 4294967295:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            elif (result[0] == "" or " ") and (result[1] == "" or " ") and (result[2] == "" or " "):
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'OVERLIMIT'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'FOR', 'INNLIMIT'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'OVERLIMIT'
                            else:
                                node_feature_list[i][6] = 'INNLIMIT'
                            break

                        elif "while" in text_value:
                            infiniteloopflag = 0
                            result = re.findall('[(](.*?)[)]', text)[0]

                            if "True" == result:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'WHILE', 'ABNORM'])
                                infiniteloopflag += 1
                            else:
                                edge_list.append(
                                    [node_list[i], node_list[i], node_list[i], 2, 'WHILE', 'NORM'])

                            if infiniteloopflag != 0:
                                node_feature_list[i][6] = 'ABNORM'
                            else:
                                node_feature_list[i][6] = 'NORM'
                            break
        else:
            var_tmp_index = 0
            called_function_tmp_index = 0
            var_flag = 0
            called_function_flag = 0

            # handle current function calling other functions
            for n in range(len(allFunctionList[i])):
                text = allFunctionList[i][n]
                text_value = re.findall('[a-zA-Z0-9]+', text)

                for k in range(len(built_in_functions)):
                    if built_in_functions[k] in text:
                        varCount += 1
                        var_tmp_index = k
                        var_flag = n
                        break

                for m in range(len(otherFunctionNameList)):
                    if otherFunctionNameList[m] in text:
                        callCount += 1
                        called_function_tmp_index = m
                        called_function_flag = n
                        break

                if callCount != 0:
                    if varCount > 0:
                        if called_function_flag < var_flag:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                 'NULL'])
                            break

                        if "Assert" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'AH', 'NULL'])

                        elif "Require" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RG', 'NULL'])

                        elif "Revert" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RH', 'NULL'])

                        elif "Return" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RE', 'NULL'])

                        elif "if" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'IF', 'NULL'])

                        else:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'FW', 'NULL'])

                        edge_list.append(
                            ['VAR' + str(len(var_node_list)), otherNodeList[called_function_tmp_index], node_list[i], 4,
                             'FW', 'NULL'])

                        var_node = 0
                        var_bool_node = 0

                        for b in range(len(var_op_bool)):
                            if var_op_bool[b] in text:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'BOOL'])
                                var_bool_node += 1
                                var_node += 1
                                break

                        if var_bool_node == 0:
                            for a in range(len(var_op_assign)):
                                if var_op_assign[a] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'ASSIGN'])
                                    var_node += 1
                                    break

                        if var_node == 0:
                            var_feature_list.append(
                                ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'NULL'])

                        var_node_list.append('VAR' + str(len(var_node_list)))
                        break

                    else:
                        if "Assert" in text_value:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'AH', 'NULL'])
                            break
                        elif "Require" in text_value:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RG', 'NULL'])
                            break
                        elif "Revert" in text_value:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RH', 'NULL'])
                            break
                        elif "Return" in text_value:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'RE', 'NULL'])
                            break
                        elif "if" in text_value:
                            edge_list.append(
                                [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'IF', 'NULL'])
                            break
                        else:
                            if n == len(allFunctionList[i]) - 1:
                                edge_list.append(
                                    [node_list[i], otherNodeList[called_function_tmp_index], node_list[i], 2, 'FW',
                                     'NULL'])
                                break
                else:
                    if varCount > 0:
                        if "Assert" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'AH', 'NULL'])

                        elif "Require" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RG', 'NULL'])

                        elif "Revert" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RH', 'NULL'])

                        elif "Return" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'RE', 'NULL'])

                        elif "if" in text_value:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'IF', 'NULL'])

                        else:
                            edge_list.append(
                                [node_list[i], "VAR" + str(len(var_node_list)), node_list[i], 2, 'FW', 'NULL'])

                        var_node = 0
                        var_bool_node = 0

                        for b in range(len(var_op_bool)):
                            if var_op_bool[b] in text:
                                var_feature_list.append(
                                    ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'BOOL'])
                                var_bool_node += 1
                                var_node += 1
                                break

                        if var_bool_node == 0:
                            for a in range(len(var_op_assign)):
                                if var_op_assign[a] in text:
                                    var_feature_list.append(
                                        ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'ASSIGN'])
                                    var_node += 1
                                    break

                        if var_node == 0:
                            var_feature_list.append(
                                ["VAR" + str(len(var_node_list)), node_list[i], 3, 'INNFUN', 'NULL'])

                        var_node_list.append('VAR' + str(len(var_node_list)))
                        break

            if callCount > 0 or varCount > 0:
                node_feature_list.append([node_list[i], functionReTypeList[i], ['Contract'], 1, 1, 'INNCALL', 'NULL'])
            else:
                node_feature_list.append([node_list[i], functionReTypeList[i], ['Contract'], 0, 0, 'INNCALL', 'NULL'])

    for i in range(len(var_feature_list)):
        node_feature_list.append(var_feature_list[i])

    # Handling some duplicate elements, the filter leaves a unique
    edge_list = list(set([tuple(t) for t in edge_list]))
    edge_list = [list(v) for v in edge_list]

    for i in range(len(node_feature_list)):
        if node_feature_list[i][0] in main_point and "FALLBACK" in node_feature_list[i][2]:
            node_feature_list[i][5] = 'FALLCALL'

    for i in range(len(node_feature_list)):
        if node_feature_list[i][0] in var_point and node_feature_list[i][1] == 'FALLBACK':
            node_feature_list[i][2] = 1

    return node_feature_list, var_feature_list, edge_list


def printResult(file, node_feature_list, edge_list):
    main_point = ['FUN1', 'FUN2', 'FUN3', 'FUN4', 'FUN5', 'FUN6', 'FUN7', 'FUN8', 'FALLBACK', 'Contract']

    for i in range(len(node_feature_list)):
        if node_feature_list[i][0] in main_point:
            for j in range(0, len(node_feature_list[i][2]), 2):
                if j + 1 < len(node_feature_list[i][2]):
                    tmp = node_feature_list[i][2][j] + "," + node_feature_list[i][2][j + 1]
                elif len(node_feature_list[i][2]) == 1:
                    tmp = node_feature_list[i][2][j]

            node_feature_list[i][2] = tmp

    nodeOutPath = "../../data/infinite_loop/graph_data/nodes/" + file
    edgeOutPath = "../../data/infinite_loop/graph_data/edges/" + file

    f_node = open(nodeOutPath, 'a', encoding="utf-8")
    for i in range(len(node_feature_list)):
        result = " ".join(np.array(node_feature_list[i]))
        f_node.write(result + '\n')
    f_node.close()

    f_edge = open(edgeOutPath, 'a', encoding="utf-8")
    for i in range(len(edge_list)):
        result = " ".join(np.array(edge_list[i]))
        f_edge.write(result + '\n')
    f_edge.close()


if __name__ == "__main__":
    inputFile = "../../data/infinite_loop/contract/loopwhile555.c"
    node_feature_list, var_feature_list, edge_list = generate_graph(inputFile)
    node_feature_list = sorted(node_feature_list, key=lambda x: (x[0]))
    var_feature_list = sorted(var_feature_list, key=lambda x: (x[0]))
    edge_list = sorted(edge_list, key=lambda x: (x[2], x[3]))
    print("node_feature", node_feature_list)
    print("var_feature", var_feature_list)
    print("edge_feature", edge_list)


    inputFileDir = "../../data/infinite_loop/contract/"
    dirs = os.listdir(inputFileDir)
    start_time = time.time()
    for file in dirs:
        inputFilePath = inputFileDir + file
        print(inputFilePath)
        node_feature_list, var_feature_list, edge_list = generate_graph(inputFilePath)
        node_feature_list = sorted(node_feature_list, key=lambda x: (x[0]))
        edge_list = sorted(edge_list, key=lambda x: (x[2], x[3]))
        printResult(file, node_feature_list, edge_list)

    end_time = time.time()
    print(end_time - start_time)

