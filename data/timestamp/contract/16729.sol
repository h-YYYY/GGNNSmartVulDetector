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
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

}


contract Crowdsale {
  using SafeMath for uint256;

   
  address public creator;

   
  StandardToken public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
    
  uint256 public periodSales;

   
  uint256 public periodSalesLimit;

   
  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, StandardToken _token,uint256 _periodSalesLimit) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
    periodSalesLimit = _periodSalesLimit;
    creator = msg.sender;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(tokens);

    _forwardFunds();
     
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(periodSalesLimit >=  periodSales);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
 
 
 

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(uint256 _tokens) internal {
     
    periodSales = periodSales.add(_tokens);
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
  
   
  function nextPeriod() public onlyCreator {
    periodSales = 0;
  }
}

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;
  
   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }
  
   
  modifier onlyWhileClose {
     
    require(block.timestamp >=  closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
  
}
 
contract LDTCrowdsale is TimedCrowdsale {
  uint256 public _rate = 4000; 
  address public _wallet = 0x14155a2582a5Eeb146bD288AdB1666d46300C272;
  StandardToken public _token = StandardToken(0x76a6Baa20598B6d203d3EAe6CC87E326bCB60e43);
  uint256 public openTime = 1538359200;  
  uint256 public closeTime = 1567303200;  
  uint256 public _maxPeriodSalesLimit = 10000 *(10 ** 18);

   
  function checkStatus() public view returns(uint256 weiRaised_, uint256 rate_, address wallet_, uint256 periodSales_) {
    return (weiRaised,rate,wallet,periodSales);
  }
  
   
  function withdrawal() public onlyCreator onlyWhileClose returns (bool) {
     
    uint forSale = token.balanceOf(address(this));
    token.transfer(creator, forSale);
  }
  
  function LDTCrowdsale()
  public
  Crowdsale(_rate, _wallet, _token, _maxPeriodSalesLimit)
  TimedCrowdsale(openTime,closeTime){

  }
}