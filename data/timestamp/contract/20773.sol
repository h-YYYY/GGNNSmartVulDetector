pragma solidity ^0.4.19;

 

interface tokenRecipient { function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public; }

contract ILOTContract {

    string public name = "ILOT Interest-Paying Lottery Token";
    string public symbol = "ILOT";
    
     
    string public site_url = "https://ILOT.io/";

    bytes32 private current_jackpot_hash = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    uint8 public decimals = 18;
    uint public totalSupply = 0;  
    uint public interestRate = 15;  
    uint tokensPerEthereum = 147000;  
    uint public jackpotDifficulty = 6;
    address public owner;

    function ILOTContract() public {
        owner = msg.sender;
    }

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint) public depositTotal;  
    mapping (address => uint) public lastBlockInterestPaid;

     
    event Transfer(address indexed from, address indexed to, uint bhtc_value);
    event Burn(address indexed from, uint bhtc_value);
    event GameResult(address player, uint zeroes);
    event BonusPaid(address to, uint bhtc_value);
    event InterestPaid(address to, uint bhtc_value);
    event Jackpot(address winner, uint eth_amount);

    uint maintenanceDebt;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function getInterest(address _to) public view returns (uint interest) {

        if (lastBlockInterestPaid[_to] > 0) {
            interest = ((block.number - lastBlockInterestPaid[_to]) * balanceOf[_to] * interestRate) / (86400000);
        } else {
            interest = 0;
        }

        return interest;
    }

     
    function getBonus(address _to) public view returns (uint interest) {
        return ((depositTotal[_to] * tokensPerEthereum) / 100);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
         
        payInterest(_from);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function setUrl(string u) public onlyOwner {
        site_url = u;
    }

    function getUrl() public view returns (string) {
        return site_url;
    }

     
    function setDifficulty(uint z) public onlyOwner {
        jackpotDifficulty = z;
    }

     
    function getDifficulty() public view returns (uint) {
        return jackpotDifficulty;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function chown(address to) public onlyOwner { owner = to; }

    function burn(uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }

     
    function payInterest(address _to) private {

        uint interest = getInterest(_to);

        if (interest > 0) {
            require( (balanceOf[_to] + interest) > balanceOf[_to]);
             
            balanceOf[msg.sender] += interest;
            totalSupply += interest;
            Transfer(this, msg.sender, interest);
            InterestPaid(_to, interest);
        }

        lastBlockInterestPaid[_to] = block.number;

    }

     
    function payBonus(address _to) private {
        if (depositTotal[_to] > 0) {
            uint bonus = getBonus(_to);
            if (bonus > 0) {
                require( (balanceOf[_to] + bonus) > balanceOf[_to]);
                balanceOf[_to] +=  bonus;
                totalSupply += bonus;
                Transfer(this, _to, bonus);
                BonusPaid(_to, bonus);
            }
        }
    }

    function hashDifficulty(bytes32 hash) public pure returns(uint) {
        uint diff = 0;

        for (uint i=0;i<32;i++) {
            if (hash[i] == 0) {
                diff++;
            } else {
                return diff;
            }
        }

        return diff;
    }

     
    function addressToString(address x) private pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

     
    function () public payable {

         
        if (msg.sender == owner) {
            return;
        }

        if (msg.value > 0) {

             
            uint mfee = (2 * msg.value) / 100;

             
            if (address(this).balance >= mfee) {
                if (address(this).balance >= (mfee + maintenanceDebt) ) {
                     
                    owner.transfer(mfee + maintenanceDebt);
                    maintenanceDebt = 0;
                } else {
                     
                    owner.transfer(mfee);
                }

            } else {
                maintenanceDebt += mfee;
            }

             
            uint tokenAmount = tokensPerEthereum * msg.value;
            if (tokenAmount > 0) {
                require( (balanceOf[msg.sender] + tokenAmount) > balanceOf[msg.sender]);

                 
                payBonus(msg.sender);

                 
                payInterest(msg.sender);

                 
                balanceOf[msg.sender] += tokenAmount;
                totalSupply += tokenAmount;
                Transfer(this, msg.sender, tokenAmount);

                 
                depositTotal[msg.sender] += msg.value;

                string memory ats = addressToString(msg.sender);

                 
                current_jackpot_hash = keccak256(current_jackpot_hash, ats, block.coinbase, block.number, block.timestamp);
                uint diffx = hashDifficulty(current_jackpot_hash);

                if (diffx >= jackpotDifficulty) {
                     
                    Jackpot(msg.sender, address(this).balance);
                    msg.sender.transfer(address(this).balance);
                }

                 
                GameResult(msg.sender, diffx);

            }
        }
    }

}