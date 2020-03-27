pragma solidity ^0.4.18;

 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for(uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



 
contract XmasCoin is StandardToken, Ownable, TokenDestructible {

  string public constant name = "XmasCoin";
  string public constant symbol = "XMX";
  uint8 public constant decimals = 18;
  string public constant version = "1.0";

    address public constant partnersWallet = 0x3cEC63f5413aeD639b5903520241BF0ba88dEDbd;
    address public constant bountyWallet = 0x5D7Eaa2d20B51ac8288C49083728b419393cF5eF;

    uint256 public totalSupply = 10000000 * (10 ** uint256(decimals));

   
  function XmasCoin() public {
    balances[msg.sender] = totalSupply;

    uint256 partners = totalSupply.div(100).mul(24);  
    transfer(partnersWallet, partners);
    uint256 bounty = totalSupply.div(100).mul(1);  
    transfer(bountyWallet, bounty);
    
  }

    
    function burn(uint256 _value) public onlyOwner {
         
        balances[owner] -= _value;
        totalSupply -= _value;
    }
}

 
contract XmasCoinCrowdsale is Ownable, Pausable, TokenDestructible {
  using SafeMath for uint256;

   
  XmasCoin public token;

   
   
   
  uint256 public tokenRaised;

    uint256 public constant cap = 7500000 * (10 ** uint256(18));

    bool public crowdsaleClosed = false;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  uint256 constant public startTime = 1512305200;
  uint256 constant public endTime = 1515369599;
  address constant public wallet = 0xE0D9f548E5A62C7a06F0690edE9621BF17620683;

  function XmasCoinCrowdsale() public {
    token = new XmasCoin();
  }



   
   
  function getRate() public constant returns (uint256) {  
    if      (block.timestamp <= 1513382399)          return 45000;  
    else if (block.timestamp <= 1514246399)          return 39000;
    else if (block.timestamp <= 1514764799)          return 36000;
    return 30000;
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(getRate()).div(10);
   

     
     
    tokenRaised = tokenRaised.add(tokens);

     if(!((cap.sub(tokenRaised))>=0)) {
      revert();
    }

    wallet.transfer(msg.value);
    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

     
    function finalize() onlyOwner public {
        require(!crowdsaleClosed);

        if(now < endTime) {
            require(tokenRaised == cap);
        }
        require(wallet.send(this.balance));
        uint remains = cap.sub(tokenRaised);
        if (remains>0) {
          token.burn(remains);
        }

        crowdsaleClosed = true;
    }


}