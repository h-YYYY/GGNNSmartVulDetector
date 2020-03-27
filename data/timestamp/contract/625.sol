pragma solidity ^0.4.24;

 


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract VestingToken is StandardToken, Ownable {

  event Mint(
    address indexed beneficiary,
    uint256 start,
    uint256 cliff,
    uint256 duration,
    uint256 amount
  );

  event Release(
    address indexed beneficiary,
    uint256 amount
  );

  event Revoke(
    address indexed beneficiary
  );

  enum VestingStatus {
    NONEXISTENT,  
    ACTIVE,       
    REVOKED       
  }

   
  struct Vesting {
    uint256 start;           
    uint256 cliff;           
    uint256 duration;        
    uint256 totalAmount;     
    uint256 releasedAmount;  

    VestingStatus status;    
  }

  mapping(address => Vesting) public vestings;

   
  function mint(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _amount
  )
    public
    onlyOwner
    returns (bool)
  {
    Vesting storage vesting = vestings[_beneficiary];
    require(vesting.status == VestingStatus.NONEXISTENT);

    vesting.start = _start;
    vesting.cliff = _cliff;
    vesting.duration = _duration;
    vesting.totalAmount = _amount;
    vesting.releasedAmount = 0;
    vesting.status = VestingStatus.ACTIVE;

    emit Mint(_beneficiary, _start, _cliff, _duration, _amount);
    return true;
  }

   
  function release() public returns (bool)
  {
    address beneficiary = msg.sender;

    Vesting storage vesting = vestings[beneficiary];
    require(vesting.status == VestingStatus.ACTIVE);

    uint256 amount = vestedAmount(beneficiary).sub(vesting.releasedAmount);
    require(amount > 0);

    vesting.releasedAmount = vesting.releasedAmount.add(amount);
    totalSupply_ = totalSupply_.add(amount);
    balances[beneficiary] = balances[beneficiary].add(amount);

    emit Release(beneficiary, amount);
    emit Transfer(address(0), beneficiary, amount);
    return true;
  }

   
  function revoke(address _beneficiary) public onlyOwner returns (bool)
  {
    Vesting storage vesting = vestings[_beneficiary];
    require(vesting.status == VestingStatus.ACTIVE);

    vesting.status = VestingStatus.REVOKED;
    emit Revoke(_beneficiary);
    return true;
  }

   
  function vestedAmount(address _beneficiary) public view returns (uint256) {
    Vesting storage vesting = vestings[_beneficiary];

    if (block.timestamp < vesting.start.add(vesting.cliff)) {
      return 0;
    } else if (block.timestamp >= vesting.start.add(vesting.duration)) {
      return vesting.totalAmount;
    } else {
      return vesting.totalAmount.mul(
        block.timestamp.sub(vesting.start)).div(vesting.duration);
    }
  }
}


 
contract BandProtocolToken is VestingToken {
  string public name = "Band Protocol";
  string public symbol = "BAND";
  uint8 public decimals = 36;
}