pragma solidity 0.4.24;

 

 
contract ERC900 {
  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes data) public;
  function stakeFor(address user, uint256 amount, bytes data) public;
  function unstake(uint256 amount, bytes data) public;
  function totalStakedFor(address addr) public view returns (uint256);
  function totalStaked() public view returns (uint256);
  function token() public view returns (address);
  function supportsHistory() public pure returns (bool);

   
   
   
   
}

 

contract CodexStakeContractInterface is ERC900 {

  function stakeForDuration(
    address user,
    uint256 amount,
    uint256 lockInDuration,
    bytes data)
    public;

  function spendCredits(
    address user,
    uint256 amount)
    public;

  function creditBalanceOf(
    address user)
    public
    view
    returns (uint256);
}

 

 
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

 

 
pragma solidity 0.4.24;





 
contract ERC900BasicStakeContract is ERC900 {
   
  using SafeMath for uint256;

   
  ERC20 stakingToken;

   
  uint256 public defaultLockInDuration;

   
   
   
   
   
  mapping (address => StakeContract) public stakeHolders;

   
   
   
   
  struct Stake {
    uint256 unlockedTimestamp;
    uint256 actualAmount;
    address stakedFor;
  }

   
   
   
   
   
  struct StakeContract {
    uint256 totalStakedFor;

    uint256 personalStakeIndex;

    Stake[] personalStakes;

    bool exists;
  }

   
  modifier canStake(address _address, uint256 _amount) {
    require(
      stakingToken.transferFrom(_address, this, _amount),
      "Stake required");

    _;
  }

   
  constructor(ERC20 _stakingToken) public {
    stakingToken = _stakingToken;
  }

   
  function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[]) {
    uint256[] memory timestamps;
    (timestamps,,) = getPersonalStakes(_address);

    return timestamps;
  }

   
  function getPersonalStakeActualAmounts(address _address) external view returns (uint256[]) {
    uint256[] memory actualAmounts;
    (,actualAmounts,) = getPersonalStakes(_address);

    return actualAmounts;
  }

   
  function getPersonalStakeForAddresses(address _address) external view returns (address[]) {
    address[] memory stakedFor;
    (,,stakedFor) = getPersonalStakes(_address);

    return stakedFor;
  }

   
  function stake(uint256 _amount, bytes _data) public {
    createStake(
      msg.sender,
      _amount,
      defaultLockInDuration,
      _data);
  }

   
  function stakeFor(address _user, uint256 _amount, bytes _data) public {
    createStake(
      _user,
      _amount,
      defaultLockInDuration,
      _data);
  }

   
  function unstake(uint256 _amount, bytes _data) public {
    withdrawStake(
      _amount,
      _data);
  }

   
  function totalStakedFor(address _address) public view returns (uint256) {
    return stakeHolders[_address].totalStakedFor;
  }

   
  function totalStaked() public view returns (uint256) {
    return stakingToken.balanceOf(this);
  }

   
  function token() public view returns (address) {
    return stakingToken;
  }

   
  function supportsHistory() public pure returns (bool) {
    return false;
  }

   
  function getPersonalStakes(
    address _address
  )
    view
    public
    returns(uint256[], uint256[], address[])
  {
    StakeContract storage stakeContract = stakeHolders[_address];

    uint256 arraySize = stakeContract.personalStakes.length - stakeContract.personalStakeIndex;
    uint256[] memory unlockedTimestamps = new uint256[](arraySize);
    uint256[] memory actualAmounts = new uint256[](arraySize);
    address[] memory stakedFor = new address[](arraySize);

    for (uint256 i = stakeContract.personalStakeIndex; i < stakeContract.personalStakes.length; i++) {
      uint256 index = i - stakeContract.personalStakeIndex;
      unlockedTimestamps[index] = stakeContract.personalStakes[i].unlockedTimestamp;
      actualAmounts[index] = stakeContract.personalStakes[i].actualAmount;
      stakedFor[index] = stakeContract.personalStakes[i].stakedFor;
    }

    return (
      unlockedTimestamps,
      actualAmounts,
      stakedFor
    );
  }

   
  function createStake(
    address _address,
    uint256 _amount,
    uint256 _lockInDuration,
    bytes _data
  )
    internal
    canStake(msg.sender, _amount)
  {
    if (!stakeHolders[msg.sender].exists) {
      stakeHolders[msg.sender].exists = true;
    }

    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);
    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        block.timestamp.add(_lockInDuration),
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }

   
  function withdrawStake(
    uint256 _amount,
    bytes _data
  )
    internal
  {
    Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

     
    require(
      personalStake.unlockedTimestamp <= block.timestamp,
      "The current stake hasn't unlocked yet");

    require(
      personalStake.actualAmount == _amount,
      "The unstake amount does not match the current stake");

     
     
     
    require(
      stakingToken.transfer(msg.sender, _amount),
      "Unable to withdraw stake");

    stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
      .totalStakedFor.sub(personalStake.actualAmount);

    personalStake.actualAmount = 0;
    stakeHolders[msg.sender].personalStakeIndex++;

    emit Unstaked(
      personalStake.stakedFor,
      _amount,
      totalStakedFor(personalStake.stakedFor),
      _data);
  }
}

 

 
contract ERC900CreditsStakeContract is ERC900BasicStakeContract, Ownable {

   
   
  mapping (address => uint256) public creditBalances;

   
  function creditBalanceOf(
    address _user
  )
    public
    view
    returns (uint256)
  {
    return creditBalances[_user];
  }

   
  function spendCredits(
    address _user,
    uint256 _amount
  )
    public
    onlyOwner
  {
    require(
      creditBalances[_user] >= _amount,
      "Insufficient balance");

    creditBalances[_user] = creditBalances[_user].sub(_amount);
  }

   
  function stake(
    uint256 _amount,
    bytes _data
  )
    public
  {
    super.stake(
      _amount,
      _data);

    updateCreditBalance(
      msg.sender,
      _amount,
      defaultLockInDuration);
  }

   
  function stakeFor(
    address _user,
    uint256 _amount,
    bytes _data
  )
    public
  {
    super.stakeFor(
      _user,
      _amount,
      _data);

    updateCreditBalance(
      _user,
      _amount,
      defaultLockInDuration);
  }

   
  function stakeForDuration(
    address _user,
    uint256 _amount,
    uint256 _lockInDuration,
    bytes _data
  )
    public
  {
    require(
      _lockInDuration >= defaultLockInDuration,
      "Insufficient stake duration");

    super.createStake(
      _user,
      _amount,
      _lockInDuration,
      _data);

    updateCreditBalance(
      _user,
      _amount,
      _lockInDuration);
  }

   
  function updateCreditBalance(
    address _user,
    uint256 _amount,
    uint256 _lockInDuration
  )
    internal
  {
    uint256 divisor = 1 ether;

    require(
      _amount >= divisor,
      "Insufficient amount");

     
     
     
     
    uint256 rewardMultiplier = _lockInDuration / defaultLockInDuration;

    uint256 creditsAwarded = _amount.mul(rewardMultiplier).div(divisor);
    creditBalances[_user] = creditBalances[_user].add(creditsAwarded);
  }
}

 

 
contract CodexStakeContract is CodexStakeContractInterface, ERC900CreditsStakeContract {

   
  constructor(
    ERC20 _stakingToken,
    uint256 _defaultLockInDuration
  )
    public
    ERC900BasicStakeContract(_stakingToken)
  {
    defaultLockInDuration = _defaultLockInDuration;
  }

   
  function setDefaultLockInDuration(
    uint256 _defaultLockInDuration
  )
    external
    onlyOwner
  {
    defaultLockInDuration = _defaultLockInDuration;
  }
}