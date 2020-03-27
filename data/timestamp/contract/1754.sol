pragma solidity ^0.4.13;

interface ERC777TokensOperator {
  function madeOperatorForTokens(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes userData,
    bytes operatorData
  ) public;
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

interface ERC20Token {
    function name() public constant returns (string);  
    function symbol() public constant returns (string);  
    function decimals() public constant returns (uint8);  
    function totalSupply() public constant returns (uint256);  
    function balanceOf(address owner) public constant returns (uint256);  
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);  

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC820Registry {
  function getManager(address addr) public view returns(address);
  function setManager(address addr, address newManager) public;
  function getInterfaceImplementer(address addr, bytes32 iHash) public view returns (address);
  function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract UnstructuredOwnable {
   
  event OwnershipTransferred(address previousOwner, address newOwner);
  event OwnerSet(address newOwner);

   
  address private _owner;

   
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

   
  constructor () public {
    setOwner(msg.sender);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  function setOwner(address newOwner) internal {
    _owner = newOwner;
    emit OwnerSet(newOwner);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

contract Pausable is UnstructuredOwnable {
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

interface Lockable {
    function lockAndDistributeTokens(
      address _tokenHolder, 
      uint256 _amount, 
      uint256 _percentageToLock, 
      uint256 _unlockTime
    ) public;
    function getAmountOfUnlockedTokens(address tokenOwner) public returns(uint);

    event LockedTokens(address indexed tokenHolder, uint256 amountToLock, uint256 unlockTime);
}

interface ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function granularity() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);

    function send(address to, uint256 amount) public;
    function send(address to, uint256 amount, bytes userData) public;

    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function operatorSend(
      address from, 
      address to, 
      uint256 amount, 
      bytes userData, 
      bytes operatorData
    ) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes userData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ERC777TokensSender {
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) public;
}

contract ERC820Implementer {
  ERC820Registry internal erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);
   
  function setIntrospectionRegistry(address _erc820Registry) internal {
    erc820Registry = ERC820Registry(_erc820Registry);
  }

  function getIntrospectionRegistry() public view returns(address) {
    return erc820Registry;
  }

  function setInterfaceImplementation(string ifaceLabel, address impl) internal {
    bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
    erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
  }

  function interfaceAddr(address addr, string ifaceLabel) internal view returns(address) {
    bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
    return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
  }

  function delegateManagement(address newManager) internal {
    erc820Registry.setManager(this, newManager);
  }
}

contract Basic777 is Pausable, ERC20Token, ERC777Token, Lockable, ERC820Implementer {
  using SafeMath for uint256;
  
  string private mName;
  string private mSymbol;
  uint256 private mGranularity;
  uint256 private mTotalSupply;
  bool private _initialized;
  
  bool private mErc20compatible;
  
  mapping(address => uint) private mBalances;
  mapping(address => lockedTokens) private mLockedBalances;
  mapping(address => mapping(address => bool)) private mAuthorized;
  mapping(address => mapping(address => uint256)) private mAllowed;
  
  struct lockedTokens {
    uint amount;
    uint256 timeLockedUntil;
  }
  
   
  constructor () public { }
  
   
   
   
   
   
   
  function initialize (
    string _name,
    string _symbol,
    uint256 _granularity,
    address _eip820RegistryAddr,
    address _owner
  )  public {
    require(!_initialized, "This contract has already been initialized. You can only do this once.");
    mName = _name;
    mSymbol = _symbol;
    mErc20compatible = true;
    setOwner(_owner);
    require(_granularity >= 1, "The granularity must be >= 1");
    mGranularity = _granularity;
    setIntrospectionRegistry(_eip820RegistryAddr);
    setInterfaceImplementation("ERC20Token", this);
    setInterfaceImplementation("ERC777Token", this);
    setInterfaceImplementation("Lockable", this);
    setInterfaceImplementation("Pausable", this);
    _initialized = true;
  }

  function initialized() public  view returns(bool) {
    return _initialized;
  }
  
  function getIntrospectionRegistry() public view returns(address){
    return address(erc820Registry);
  }
  
   
   
   
  function name() public constant returns (string) { return mName; }  
  
   
  function symbol() public constant returns (string) { return mSymbol; }  
  
   
  function granularity() public view returns (uint256) { return mGranularity; }
  
   
  function totalSupply() public constant returns (uint256) { return mTotalSupply; }  
  
   
   
   
  function balanceOf(address _tokenHolder) public constant returns (uint256) {  
    return mBalances[_tokenHolder]; 
  }
  
   
   
   
  function send(address _to, uint256 _amount) public whenNotPaused {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      true
    );
  }
  
   
   
   
  function send(address _to, uint256 _amount, bytes _userData) public whenNotPaused {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      _userData, 
      msg.sender, 
      "", 
      true
    );
  }
  
   
   
  function authorizeOperator(address _operator) public whenNotPaused {
    require(_operator != msg.sender, "You cannot authorize yourself as an operator");
    mAuthorized[_operator][msg.sender] = true;
    emit AuthorizedOperator(_operator, msg.sender);
  }
  
   
   
   
   
   
   
  function approveAndCall(address _operator, uint256 _amount, bytes _operatorData) public whenNotPaused returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(msg.sender);
    require(balanceAvailable >= _amount, "The amount of unlocked tokens must be >= the amount sent");
    mAllowed[msg.sender][_operator] = _amount;
    callOperator(
      _operator, 
      msg.sender, 
      _operator, 
      _amount, 
      "0x0", 
      _operatorData, 
      true
    );
    emit Approval(msg.sender, _operator, _amount);
    return true;
  }
  
   
   
  function revokeOperator(address _operator) public whenNotPaused {
    require(_operator != msg.sender, "You cannot authorize yourself as an operator");
    mAuthorized[_operator][msg.sender] = false;
    emit RevokedOperator(_operator, msg.sender);
  }
  
   
   
   
   
  function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
    return _operator == _tokenHolder || mAuthorized[_operator][_tokenHolder];
  }
  
   
   
   
   
   
   
  function operatorSend(
    address _from, 
    address _to, 
    uint256 _amount, 
    bytes _userData, 
    bytes _operatorData
  ) public whenNotPaused {
    require(isOperatorFor(msg.sender, _from), "Only an approved operator can use operatorSend");
    doSend(
      _from, 
      _to, 
      _amount, 
      _userData, 
      msg.sender, 
      _operatorData, 
      true
    );
  }
  
   
   
   
   
   
   
   
  function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public onlyOwner {
    requireMultiple(_amount);
    mTotalSupply = mTotalSupply.add(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);
    
    callRecipient(
      msg.sender, 
      0x0, 
      _tokenHolder, 
      _amount, 
      "", 
      _operatorData, 
      true
    );
    
    emit Minted(
      msg.sender, 
      _tokenHolder, 
      _amount, 
      _operatorData
    );
    if (mErc20compatible) { 
      emit Transfer(0x0, _tokenHolder, _amount); 
    }
  }

  function burn(uint256 _amount, bytes _holderData) public whenNotPaused {
    doBurn(
      msg.sender, 
      msg.sender, 
      _amount, 
      _holderData, 
      ""
    );
  }

  function operatorBurn(
    address _tokenHolder, 
    uint256 _amount, 
    bytes _holderData, 
    bytes _operatorData
  ) public whenNotPaused {
    require(isOperatorFor(msg.sender, _tokenHolder), "Only and approved operator can use operatorBurn");
    doBurn(
      msg.sender, 
      _tokenHolder, 
      _amount, 
      _holderData, 
      _operatorData
    );
  }

   
   
   
   
   
   
  function doBurn(
    address _operator, 
    address _tokenHolder, 
    uint256 _amount, 
    bytes _holderData, 
    bytes _operatorData
  ) internal whenNotPaused {
    requireMultiple(_amount);
    uint balanceAvailable = getAmountOfUnlockedTokens(_tokenHolder);
    require(
      balanceAvailable >= _amount, 
      "You can only burn tokens when you have a balance grater than or equal to the amount specified"
    );

    mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
    mTotalSupply = mTotalSupply.sub(_amount);
    
    callSender(
      _operator, 
      _tokenHolder, 
      0x0, 
      _amount, 
      _holderData, 
      _operatorData
    );
    
    emit Burned(
      _operator, 
      _tokenHolder, 
      _amount, 
      _holderData, 
      _operatorData
    );
  }
  
   
   
   
   
   
  modifier erc20 () {
    require(mErc20compatible, "You can only use this function when the 'ERC20Token' interface is enabled");
    _;
  }
  
   
   
  function disableERC20() public onlyOwner {
    mErc20compatible = false;
    setInterfaceImplementation("ERC20Token", 0x0);
  }
  
   
   
  function enableERC20() public onlyOwner {
    mErc20compatible = true;
    setInterfaceImplementation("ERC20Token", this);
  }
  
   
   
  function decimals() public erc20 view returns (uint8) { return uint8(18); }  
  
   
   
   
   
  function transfer(address _to, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    doSend(
      msg.sender, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      false
    );
    return true;
  }
  
   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(_from);
    require(
      balanceAvailable >= _amount, 
      "You can only use transferFrom when you specify an amount of tokens >= the '_from' address's amount of unlocked tokens"
    );
    require(
      _amount <= mAllowed[_from][msg.sender],
      "You can only use transferFrom with an amount less than or equal to the current 'mAllowed' allowance."
    );
    
     
    mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
    doSend(
      _from, 
      _to, 
      _amount, 
      "", 
      msg.sender, 
      "", 
      false
    );
    return true;
  }
  
   
   
   
   
   
  function approve(address _spender, uint256 _amount) public whenNotPaused erc20 returns (bool success) {
    uint balanceAvailable = getAmountOfUnlockedTokens(msg.sender);
    require(
      balanceAvailable >= _amount, 
      "You can only approve an amount >= the amount of tokens currently unlocked for this account"
    );
    mAllowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }
  
   
   
   
   
   
   
  function allowance(address _owner, address _spender) public erc20 constant returns (uint256 remaining) {  
    return mAllowed[_owner][_spender];
  }
  
   
   
   
   
  function requireMultiple(uint256 _amount) internal view {
    require(
      _amount.div(mGranularity).mul(mGranularity) == _amount, 
      "You can only use tokens using the granularity currently set."
    );
  }
  
   
   
   
  function isRegularAddress(address _addr) internal view returns(bool) {
    if (_addr == 0) { 
      return false; 
    }
    uint size;
    assembly { size := extcodesize(_addr) }  
    return size == 0;
  }
  
   
   
   
   
   
   
   
   
   
   
  function doSend(
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    address _operator,
    bytes _operatorData,
    bool _preventLocking
  ) private whenNotPaused {
    requireMultiple(_amount);
    uint balanceAvailable = getAmountOfUnlockedTokens(_from);
    
    callSender(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData
    );
    
    require(
      _to != address(0), 
      "You cannot invoke doSend with a the burn address (0x0) as the recipient 'to' address"
    );           
    require(
      balanceAvailable >= _amount, 
      "You can only invoke doSend when the 'from' address has an unlocked balance >= the '_amount' sent"
    );  
    
    mBalances[_from] = mBalances[_from].sub(_amount);
    mBalances[_to] = mBalances[_to].add(_amount);
    
    callRecipient(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData, 
      _preventLocking
    );
    
    emit Sent(
      _operator, 
      _from, 
      _to, 
      _amount, 
      _userData, 
      _operatorData
    );
    if (mErc20compatible) { 
      emit Transfer(_from, _to, _amount); 
    }
  }
  
   
   
   
   
   
   
   
   
   
   
   
  function callRecipient(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) private {
    address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
    if (recipientImplementation != 0) {
      ERC777TokensRecipient(recipientImplementation).tokensReceived(
        _operator, 
        _from, 
        _to, 
        _amount, 
        _userData, 
        _operatorData
      );
    } else if (_preventLocking) {
      require(
        isRegularAddress(_to),
        "When '_preventLocking' is true, you cannot invoke 'callOperator' to a contract address that does not support the 'ERC777TokensOperator' interface"
      );
    }
  }
  
   
   
   
   
   
   
   
   
   
   
  function callSender(
    address _operator,
    address _from,
    address _to,
    uint256 _amount,
    bytes _userData,
    bytes _operatorData
  ) private whenNotPaused {
    address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
    if (senderImplementation != 0) {
      ERC777TokensSender(senderImplementation).tokensToSend(
        _operator, 
        _from, 
        _to, 
        _amount, 
        _userData, 
        _operatorData
      );
    }
  }
  
   
   
   
   
   
   
   
   
   
   
   
  function callOperator(
    address _operator,
    address _from,
    address _to,
    uint256 _value,
    bytes _userData,
    bytes _operatorData,
    bool _preventLocking
  ) private {
    address recipientImplementation = interfaceAddr(_to, "ERC777TokensOperator");
    if (recipientImplementation != 0) {
      ERC777TokensOperator(recipientImplementation).madeOperatorForTokens(
        _operator, 
        _from, 
        _to, 
        _value, 
        _userData, 
        _operatorData
      );
    } else if (_preventLocking) {
      require(
        isRegularAddress(_to),
        "When '_preventLocking' is true, you cannot invoke 'callOperator' to a contract address that does not support the 'ERC777TokensOperator' interface"
      );
    }
  }
  
   
   
   
   
   
  function lockAndDistributeTokens(
    address _tokenHolder, 
    uint256 _amount, 
    uint256 _percentageToLock, 
    uint256 _unlockTime
  ) public onlyOwner {
    requireMultiple(_amount);
    require(
      _percentageToLock <= 100 && 
      _percentageToLock > 0, 
      "You can only lock a percentage between 0 and 100."
    );
    require(
      mLockedBalances[_tokenHolder].amount == 0, 
      "You can only lock one amount of tokens for a given address. It is currently indicating that there are already locked tokens for this address."
    );
    uint256 amountToLock = _amount.mul(_percentageToLock).div(100);
    mBalances[msg.sender] = mBalances[msg.sender].sub(_amount);
    mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);
    mLockedBalances[_tokenHolder] = lockedTokens({
      amount: amountToLock,
      timeLockedUntil: _unlockTime
    });
    
    callRecipient(
      msg.sender, 
      0x0, 
      _tokenHolder, 
      _amount, 
      "", 
      "", 
      true
    );

    emit LockedTokens(_tokenHolder, amountToLock, _unlockTime);
    
    if (mErc20compatible) { 
      emit Transfer(0x0, _tokenHolder, _amount); 
    }
  }
  
   
   
  function getAmountOfUnlockedTokens(address _tokenOwner) public returns(uint) {
    uint balanceAvailable = mBalances[_tokenOwner];
    if (
      mLockedBalances[_tokenOwner].amount != 0 && 
      mLockedBalances[_tokenOwner].timeLockedUntil > block.timestamp  
    ){
      balanceAvailable = balanceAvailable.sub(mLockedBalances[_tokenOwner].amount);
    } else if (
      mLockedBalances[_tokenOwner].amount != 0 && 
      mLockedBalances[_tokenOwner].timeLockedUntil < block.timestamp  
    ) {
      mLockedBalances[_tokenOwner] = lockedTokens({
        amount: 0,
        timeLockedUntil: 0
      });  
    }
    return balanceAvailable;
  }
}

contract KPXV0_1_0 is Basic777 {
  constructor() public Basic777() { }
}

interface ERC777TokensRecipient {
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint amount,
    bytes userData,
    bytes operatorData
  ) public;
}