pragma solidity 0.4.19;

 

 
interface NokuPricingPlan {
     
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

     
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
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

 

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

 
contract NokuTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogNokuTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

     
    address public wallet;

     
    uint256 public burningPercentage;

     
    uint256 public burnedTokens;

     
    uint256 public transferredTokens;

     
    function NokuTokenBurner(address _wallet) public {
        require(_wallet != address(0));
        
        wallet = _wallet;
        burningPercentage = 100;

        LogNokuTokenBurnerCreated(msg.sender, _wallet);
    }

     
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 <= _burningPercentage && _burningPercentage <= 100);
        require(_burningPercentage != burningPercentage);
        
        burningPercentage = _burningPercentage;

        LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

     
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0));
        require(_amount > 0);

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn > 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer > 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

 

 
contract NokuFlatPlan is NokuPricingPlan, Ownable {
    using SafeMath for uint256;

    event LogNokuFlatPlanCreated(
        address indexed caller,
        uint256 indexed paymentInterval,
        uint256 indexed flatFee,
        address nokuMasterToken,
        address tokenBurner
    );
    event LogPaymentIntervalChanged(address indexed caller, uint256 indexed paymentInterval);
    event LogFlatFeeChanged(address indexed caller, uint256 indexed flatFee);

     
    uint256 public paymentInterval;

     
    uint256 public nextPaymentTime;

     
    uint256 public flatFee;

     
    address public nokuMasterToken;

     
    address public tokenBurner;

    function NokuFlatPlan(
        uint256 _paymentInterval,
        uint256 _flatFee,
        address _nokuMasterToken,
        address _tokenBurner
    )
    public
    {
        require(_paymentInterval != 0);
        require(_flatFee != 0);
        require(_nokuMasterToken != 0);
        require(_tokenBurner != 0);

        paymentInterval = _paymentInterval;
        flatFee = _flatFee;
        nokuMasterToken = _nokuMasterToken;
        tokenBurner = _tokenBurner;

        nextPaymentTime = block.timestamp;

        LogNokuFlatPlanCreated(
            msg.sender, _paymentInterval, _flatFee, _nokuMasterToken, _tokenBurner);
    }

    function setPaymentInterval(uint256 _paymentInterval) public onlyOwner {
        require(_paymentInterval != 0);
        require(_paymentInterval != paymentInterval);
        
        paymentInterval = _paymentInterval;

        LogPaymentIntervalChanged(msg.sender, _paymentInterval);
    }

    function setFlatFee(uint256 _flatFee) public onlyOwner {
        require(_flatFee != 0);
        require(_flatFee != flatFee);
        
        flatFee = _flatFee;

        LogFlatFeeChanged(msg.sender, _flatFee);
    }

    function isValidService(bytes32 _serviceName) public pure returns(bool isValid) {
        return _serviceName != 0;
    }

     
    function payFee(bytes32 _serviceName, uint256 _multiplier, address _client) public returns(bool paid) {
        require(isValidService(_serviceName));
        require(_multiplier != 0);
        require(_client != 0);
        
        require(block.timestamp < nextPaymentTime);

        return true;
    }

    function usageFee(bytes32 _serviceName, uint256 _multiplier) public constant returns(uint fee) {
        require(isValidService(_serviceName));
        require(_multiplier != 0);
        
        return 0;
    }

    function paySubscription(address _client) public returns(bool paid) {
        require(_client != 0);

        nextPaymentTime = nextPaymentTime.add(paymentInterval);

        assert(ERC20(nokuMasterToken).transferFrom(_client, tokenBurner, flatFee));

        NokuTokenBurner(tokenBurner).tokenReceived(nokuMasterToken, flatFee);

        return true;
    }
}