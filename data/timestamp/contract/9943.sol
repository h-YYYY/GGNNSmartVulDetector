pragma solidity ^0.4.21;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function batchTransfer(address[] _receivers, uint256 _value) public onlyOwner whenNotPaused returns (bool) {
        uint cnt = _receivers.length;
        uint256 amount = _value.mul(uint256(cnt));
        require(cnt > 0 && cnt <= 20);
        require(_value > 0 && balances[msg.sender] >= amount);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        for (uint i = 0; i < cnt; i++) {
            balances[_receivers[i]] = balances[_receivers[i]].add(_value);
            emit Transfer(msg.sender, _receivers[i], _value);
        }
        return true;
    }
}

 
contract UvtToken is PausableToken {
     
    uint256 public tokenDestroyed;

     
    address public devTeam;
    address public investor;
    address public ecoBuilder;

    event Burn(address indexed _from, uint256 _tokenDestroyed, uint256 _timestamp);

     
    function initializeSomeAddress(address newDevTeam, address newInvestor, address newEcoBuilder) onlyOwner public {
        require(newDevTeam != address(0) && newInvestor != address(0) && newEcoBuilder != address(0));
        require(devTeam == 0x0 && investor == 0x0 && ecoBuilder == 0x0);

        devTeam = newDevTeam;
        investor = newInvestor;
        ecoBuilder = newEcoBuilder;
    }

     
    function burn(uint256 _burntAmount) onlyOwner public returns (bool success) {
        require(balances[msg.sender] >= _burntAmount && _burntAmount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_burntAmount);
        totalSupply = totalSupply.sub(_burntAmount);
        tokenDestroyed = tokenDestroyed.add(_burntAmount);
        require(tokenDestroyed < 10000000000 * (10 ** (uint256(decimals))));
        emit Transfer(address(this), 0x0, _burntAmount);
        emit Burn(msg.sender, _burntAmount, block.timestamp);
        return true;
    }

     
    string public name = "User Value Token";
    string public symbol = "UVT";
    string public version = '1.0.0';
    uint8 public decimals = 18;

     
    constructor() public{

        totalSupply = 10000000000 * (10 ** (uint256(decimals)));
        balances[msg.sender] = totalSupply;
         
    }


    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        if (devTeam != 0x0 && _to == devTeam)
        {
             
            require(balances[_to].add(_value) <= totalSupply.div(5));
        }
        if (investor != 0x0 && _to == investor)
        {
             
            require(balances[_to].add(_value) <= totalSupply.div(5));
        }
        if (ecoBuilder != 0x0 && _to == ecoBuilder)
        {
             
            require(balances[_to].add(_value) <= totalSupply.div(5));
        }
        return super.transfer(_to, _value);
    }
}