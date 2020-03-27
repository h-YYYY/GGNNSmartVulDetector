pragma solidity ^0.4.23;
interface iERC20{
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
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

contract PalmCoin is iERC20 {
    using SafeMath for uint256;
    uint public _totalSupply = 7500000000000000000000000;

    string public constant symbol = "PALM";
    string public constant name = "PalmCoin";
    uint8 public constant decimals = 18;

    address public owner;

     
    uint256 public _releaseTime;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor(address _owner, uint256 unlockTimestamp) public {
        balances[_owner] = _totalSupply;
        owner = _owner;
        _releaseTime = unlockTimestamp;
        emit LockedUntil(unlockTimestamp);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier whenNotLocked() {
      require(msg.sender == owner || block.timestamp > _releaseTime);
      _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner returns (bool) {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setLock(uint256 releaseTime) external onlyOwner {
         
        require(releaseTime < 1559365200);
        _releaseTime = releaseTime;
        emit LockedUntil(releaseTime);
    }

    function totalSupply() public constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public whenNotLocked onlyPayloadSize(2 * 32) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotLocked returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

      
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
       allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
       emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
       return true;
    }


    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event LockedUntil(uint256 timestamp);

}