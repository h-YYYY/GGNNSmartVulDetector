InputSmartContract = "./reentrancy/result_tuned/Reentrancy_AutoExtract_fullnodes.json"
SmartContractNumber = "./reentrancy/graph_number_1671.txt"
out = "./reentrancy/result_tuned/Reentrancy_AutoExtract_fullnodes_1671.json"

ContractNumber = open(SmartContractNumber, "r")
ContractNumbers = ContractNumber.readlines()
f = open(InputSmartContract, "r")
lines = f.readlines()
f_w = open(out, "a")

for i in range(len(ContractNumbers)):
    number = ContractNumbers[i].strip()

    for j in range(int(number)):
        f_w.write(lines[i])
        print(j)

