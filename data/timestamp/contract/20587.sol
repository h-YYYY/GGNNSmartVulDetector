pragma solidity ^0.4.21;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


interface Token {
    function totalSupply() external view returns (uint _supply);
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function decimals() external view returns (uint8 _decimals);
    function balanceOf(address _owner) external view returns (uint _balance);
    function transfer(address _to, uint _tokens) external returns (bool _success);
    function transferFrom(address _from, address _to, uint _tokens) external returns (bool _success);

    function allowance(address _owner, address _spender) external view returns (uint _remaining);
    function approve(address _spender, uint _tokens) external returns (bool _success);

    event Transfer(address indexed _from, address indexed _to, uint _tokens, bytes indexed _data);
    event Approval(address indexed _owner, address indexed _spender, uint _tokens);
}

contract StandardToken is Token {
    using SafeMath for uint;

    function processTransfer(address _from, address _to, uint256 _value, bytes _data) internal returns (bool success) {
        if (balances[_from] >= _value && _value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);

             
             
            if (isContract(_to)) {
                iReceiver receiver = iReceiver(_to);
                receiver.tokenFallback(_from, _value, _data);
            }

            emit Transfer(_from, _to, _value, _data);
            return true;
        }
        return false;
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value, bytes _data) external returns (bool success) {
        return processTransfer(msg.sender, _to, _value, _data);
    }

     
     
     
     
    function transfer(address _to, uint256 _value) external returns (bool success) {
        bytes memory empty;
        return processTransfer(msg.sender, _to, _value, empty);
    }
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (allowed[_from][msg.sender] >= _value) {
            bytes memory empty;
            return processTransfer(_from, _to, _value, empty);
        }
        return false;
    }

     
     
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    string public name;                   
    uint8 public decimals;                 
    string public symbol;                  
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    function totalSupply() external view returns (uint _supply) {
        return totalSupply;
    }
    
    function name() external view returns (string _name) {
        return name;
    }
    
    function symbol() external view returns (string _symbol) {
        return symbol;
    }
    
    function decimals() external view returns (uint8 _decimals) {
        return decimals;
    }

    function isContract(address _addr) internal view returns (bool _is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

contract FLOCK is StandardToken {  
    using SafeMath for uint;

     

     
    string public version = "H1.0"; 
    uint256 public totalEthInWei;          
    address public fundsWallet;            

    Round[] rounds;
    struct Round {
        uint start;
        uint end;
        uint price;
    }

     
     
    function FLOCK() public {
        totalSupply = 10000000000;           
        balances[msg.sender] = totalSupply;  
        name = "FLOCK";                      
        decimals = 0;                        
        symbol = "FLK";                      
        fundsWallet = msg.sender;            

        uint ts = 1523764800;
        rounds.push(Round(ts, ts += 5 days, 500000));  
        rounds.push(Round(ts, ts += 5 days, 500000));  
        rounds.push(Round(ts, ts += 2 days, 250000));  
        rounds.push(Round(ts, ts += 2 days, 166667));  
        rounds.push(Round(ts, ts += 2 days, 125000));  
        rounds.push(Round(ts, ts += 2 days, 100000));  
        rounds.push(Round(ts, ts += 2 days, 83333));  
        rounds.push(Round(ts, ts += 2 days, 71429));  
        rounds.push(Round(ts, ts += 2 days, 62500));  
        rounds.push(Round(ts, ts += 2 days, 55556));  
        rounds.push(Round(ts, ts += 2 days, 50000));  
    }

     
     
    function unitsOneEthCanBuy() public view returns (uint _units) {
        for (uint i = 0; i < rounds.length; i++) {
            Round memory round = rounds[i];
            if (block.timestamp >= round.start && block.timestamp < round.end) {
                return round.price;
            }
        }
        return 0;
    }

     
     
    function() external payable {
        uint ethInWei = msg.value;
        totalEthInWei = totalEthInWei + ethInWei;
        uint perEth = unitsOneEthCanBuy();
        
         
         
        uint256 amount = ethInWei.mul(perEth).div(10**uint(18 - decimals));

        require(amount > 0);
        require(balances[fundsWallet] >= amount);

         
        fundsWallet.transfer(msg.value);                               

        bytes memory empty;
        processTransfer(fundsWallet, msg.sender, amount, empty);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _data) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
        iApprover(_spender).receiveApproval(msg.sender, _value, address(this), _data);
        return true;
    }

     
    function reclaimERC20(address _token, uint _tokens) external returns (bool _success) {
        require(msg.sender == fundsWallet);
        return Token(_token).transfer(msg.sender, _tokens);
    }
}

interface iReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

interface iApprover {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _data) external;
}