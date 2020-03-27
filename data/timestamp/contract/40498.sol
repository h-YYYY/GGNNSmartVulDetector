contract tickingBomb {

    struct team {
        string name;
        uint lastUpdate;
        address[] members;
        uint nbrMembers;
    }

    uint public constant DELAY =  60 * 60 * 24;  
    uint public constant INVEST_AMOUNT = 1000 finney;  
    uint constant FEE = 3;

    team public red;
    team public blue;

    mapping(address => uint) public balances;
    address creator;

    string[] public historyWinner;
    uint[] public historyRed;
    uint[] public historyBlue;
    uint public gameNbr;

    function tickingBomb() {
        newRound();
        creator = msg.sender;
        gameNbr = 0;
    }

    function helpRed() {
        uint i;
        uint amount = msg.value;

         
         
        checkIfExploded();

         
        red.lastUpdate = block.timestamp;

         
        while (amount >= INVEST_AMOUNT) {
            red.members.push(msg.sender);
            red.nbrMembers++;
            amount -= INVEST_AMOUNT;
        }

         
        if (amount > 0) {
            msg.sender.send(amount);
        }
    }

    function helpBlue() {
        uint i;
        uint amount = msg.value;

         
         
        checkIfExploded();

         
        blue.lastUpdate = block.timestamp;

         
        while (amount >= INVEST_AMOUNT) {
            blue.members.push(msg.sender);
            blue.nbrMembers++;
            amount -= INVEST_AMOUNT;
        }

         
        if (amount > 0) {
            msg.sender.send(amount);
        }
    }

    function checkIfExploded() {
        if (checkTime()) {
            newRound();
        }
    }

    function checkTime() private returns(bool exploded) {
        uint i;
        uint lostAmount = 0;
        uint gainPerMember = 0;
        uint feeCollected = 0;

         
        if (red.lastUpdate == blue.lastUpdate && red.lastUpdate + DELAY < block.timestamp) {
            for (i = 0; i < red.members.length; i++) {
                balances[red.members[i]] += INVEST_AMOUNT;
            }
            for (i = 0; i < blue.members.length; i++) {
                balances[blue.members[i]] += INVEST_AMOUNT;
            }

            historyWinner.push('Tie between Red and Blue');
            historyRed.push(red.nbrMembers);
            historyBlue.push(blue.nbrMembers);
            gameNbr++;
            return true;
        }

         
        if (red.lastUpdate < blue.lastUpdate) {
             
            if (red.lastUpdate + DELAY < block.timestamp) {
                 
                 
                feeCollected += (red.nbrMembers * INVEST_AMOUNT * FEE / 100);
                balances[creator] += feeCollected;
                lostAmount = (red.nbrMembers * INVEST_AMOUNT) - feeCollected;

                gainPerMember = lostAmount / blue.nbrMembers;
                for (i = 0; i < blue.members.length; i++) {
                    balances[blue.members[i]] += (INVEST_AMOUNT + gainPerMember);
                }

                historyWinner.push('Red');
                historyRed.push(red.nbrMembers);
                historyBlue.push(blue.nbrMembers);
                gameNbr++;
                return true;
            }
            return false;
        } else {
             
            if (blue.lastUpdate + DELAY < block.timestamp) {
                 
                 
                feeCollected += (blue.nbrMembers * INVEST_AMOUNT * FEE / 100);
                balances[creator] += feeCollected;
                lostAmount = (blue.nbrMembers * INVEST_AMOUNT) - feeCollected;
                gainPerMember = lostAmount / red.nbrMembers;
                for (i = 0; i < red.members.length; i++) {
                    balances[red.members[i]] += (INVEST_AMOUNT + gainPerMember);
                }

                historyWinner.push('Blue');
                historyRed.push(red.nbrMembers);
                historyBlue.push(blue.nbrMembers);
                gameNbr++;
                return true;
            }
            return false;
        }
    }

    function newRound() private {
        red.name = "Red team";
        blue.name = "Blue team";
        red.lastUpdate = block.timestamp;
        blue.lastUpdate = block.timestamp;
        red.nbrMembers = 0;
        blue.nbrMembers = 0;
        red.members = new address[](0);
        blue.members = new address[](0);
    }

    function() {
         
        if (red.lastUpdate < blue.lastUpdate) {
            helpRed();
        } else {
            helpBlue();
        }
    }

    function collectBalance() {
        msg.sender.send(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

     
    function sendBalance(address player) {
        if (msg.sender == creator) {
            player.send(balances[player]);
        }
    }

    function newOwner(address newOwner) {
        if (msg.sender == creator) {
            creator = newOwner;
        }
    }

}