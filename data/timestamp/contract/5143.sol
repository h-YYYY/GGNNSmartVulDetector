pragma solidity 0.4.24;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

 
contract ParkadeCoin is StandardToken, Ownable {
  using SafeMath for uint256;
  string public name = "Parkade Coin";
  string public symbol = "PRKC";
  uint8 public decimals = 18;


   
  uint256 public scaling = uint256(10) ** 10;

   
  uint256 public scaledRemainder = 0;

   
  mapping(address => uint256) public scaledDividendBalances;
   
  mapping(address => uint256) public scaledDividendCreditedTo;
   
  uint256 public scaledDividendPerToken = 0;

   
  modifier onlyPayloadSize(uint size) { 
    assert(msg.data.length >= size + 4);
    _;    
  }

  constructor() public {
     
    totalSupply_ = uint256(400000000) * (uint256(10) ** decimals);
     
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

   
  function update(address account) 
  internal 
  {
     
     
    uint256 owed = scaledDividendPerToken.sub(scaledDividendCreditedTo[account]);

     
     
    scaledDividendBalances[account] = scaledDividendBalances[account].add(balances[account].mul(owed));
     
    scaledDividendCreditedTo[account] = scaledDividendPerToken;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Deposit(uint256 value);
  event Withdraw(uint256 paidOut, address indexed to);

  mapping(address => mapping(address => uint256)) public allowance;

   
  function transfer(address _to, uint256 _value) 
  public 
  onlyPayloadSize(2*32) 
  returns (bool success) 
  {
    require(balances[msg.sender] >= _value);

     
    update(msg.sender);
    update(_to);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
  public
  onlyPayloadSize(3*32)
  returns (bool success)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

     
    update(_from);
    update(_to);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function deposit() 
  public 
  payable 
  onlyOwner 
  {
     
    uint256 available = (msg.value.mul(scaling)).add(scaledRemainder);

     
    scaledDividendPerToken = scaledDividendPerToken.add(available.div(totalSupply_));

     
    scaledRemainder = available % totalSupply_;

    emit Deposit(msg.value);
  }

   
  function withdraw() 
  public 
  {
     
    update(msg.sender);

     
    uint256 amount = scaledDividendBalances[msg.sender].div(scaling);
     
    scaledDividendBalances[msg.sender] %= scaling;

     
    msg.sender.transfer(amount);

    emit Withdraw(amount, msg.sender);
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
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

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
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

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

 

 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

   
  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

   
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

 

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

contract ParkadeCoinCrowdsale is TimedCrowdsale, RefundableCrowdsale, WhitelistedCrowdsale {
  
   
   
  uint256 public firstBonusRate = 1838;
  uint256 public secondBonusRate = 1634;
  uint256 public normalRate = 1470;

   
   
  uint256 public openingTime = 1534550400;

   
   
  uint256 public firstBonusEnds = 1535155200;

   
  uint256 public secondBonusEnds = 1536364800;

   
   
  uint256 public closingTime = 1538179199;

   
   
   
  address public executor;

   
   
   
  bool refundsAllowed;

   
  address tokenTimelockContract;

  constructor
  (
    uint256 _goal,
    address _owner,
    address _executor,
    address _tokenTimelockContract,
    StandardToken _token
  )
  public 
  Crowdsale(normalRate, _owner, _token) 
  TimedCrowdsale(openingTime, closingTime)
  RefundableCrowdsale(_goal)
  {
    tokenTimelockContract = _tokenTimelockContract;
    executor = _executor;
    refundsAllowed = false;
  }

   
  modifier onlyOwnerOrExecutor() {
    require(msg.sender == owner || msg.sender == executor);
    _;
  }

   
  function currentRate() public view returns (uint256) {
    if (block.timestamp < firstBonusEnds)
    {
      return firstBonusRate;
    }
    else if (block.timestamp >= firstBonusEnds && block.timestamp < secondBonusEnds)
    {
      return secondBonusRate;
    }
    else 
    {
      return normalRate;
    }
  }

   
  function changeExecutor(address _newExec) external onlyOwnerOrExecutor {
    require(_newExec != address(0));
    executor = _newExec;
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(currentRate());
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwnerOrExecutor {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrExecutor {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwnerOrExecutor {
    whitelist[_beneficiary] = false;
  }


   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(token.balanceOf(this) > _getTokenAmount(_weiAmount));
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

   
  function claimRefund() public {
     
    require(hasClosed());

     
    if (goalReached())
    {
      require(refundsAllowed);
    }

    vault.refund(msg.sender);
  }

   
  function allowRefunds() external onlyOwner {
    require(!isFinalized);
    require(hasClosed());
    refundsAllowed = true;
    vault.enableRefunds();
  }

    
  function finalization() internal {
    require(!refundsAllowed);

     
    token.transfer(tokenTimelockContract, token.balanceOf(this));
   
    super.finalization();
  }
}