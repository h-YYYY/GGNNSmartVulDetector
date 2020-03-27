pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
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

 

 

pragma solidity ^0.4.23;






 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

 

contract InitialTokenDistribution is Ownable {
    using SafeMath for uint256;

    ERC20 public token;
    mapping (address => TokenVesting) public vested;
    mapping (address => TokenTimelock) public timelocked;
    mapping (address => uint256) public initiallyDistributed;
    bool public initialDistributionDone = false;

    modifier onInitialDistribution() {
        require(!initialDistributionDone);
        _;
    }

    constructor(ERC20 _token) public {
        token = _token;
    }

     
    function initialDistribution() internal;

     
    function totalTokensDistributed() public view returns (uint256);

     
    function processInitialDistribution() onInitialDistribution onlyOwner public {
        initialDistribution();
        initialDistributionDone = true;
    }

    function initialTransfer(address to, uint256 amount) onInitialDistribution public {
        require(to != address(0));
        initiallyDistributed[to] = amount;
        token.transferFrom(msg.sender, to, amount);
    }

    function vest(address to, uint256 amount, uint256 releaseStart, uint256 cliff, uint256 duration) onInitialDistribution public {
        require(to != address(0));
        vested[to] = new TokenVesting(to, releaseStart, cliff, duration, false);
        token.transferFrom(msg.sender, vested[to], amount);
    }

    function lock(address to, uint256 amount, uint256 releaseTime) onInitialDistribution public {
        require(to != address(0));
        timelocked[to] = new TokenTimelock(token, to, releaseTime);
        token.transferFrom(msg.sender, address(timelocked[to]), amount);
    }
}

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

contract BlockFollowInitialTokenDistribution is InitialTokenDistribution {


    uint256 public reservedTokensFunctionality;
    uint256 public reservedTokensTeam;

    address functionalityWallet;
    address teamWallet;

    constructor(
        DetailedERC20 _token,
        address _functionalityWallet,
        address _teamWallet
    )
    public
    InitialTokenDistribution(_token)
    {
        functionalityWallet = _functionalityWallet;
        teamWallet = _teamWallet;

        uint8 decimals = _token.decimals();
        reservedTokensFunctionality = 80e6 * (10 ** uint256(decimals));
        reservedTokensTeam = 10e6 * (10 ** uint256(decimals));
    }

    function initialDistribution() internal {
        initialTransfer(functionalityWallet, reservedTokensFunctionality);
        initialTransfer(teamWallet, reservedTokensTeam);
    }

    function totalTokensDistributed() public view returns (uint256) {
        return reservedTokensFunctionality + reservedTokensTeam;
    }
}