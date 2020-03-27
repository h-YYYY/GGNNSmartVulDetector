pragma solidity 0.4.21;


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
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
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract KimeraToken is MintableToken, BurnableToken {
    string public name = "Kimera";
    string public symbol = "Kimera";
    uint256 public decimals = 18;
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}


contract KimeraTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
  
     
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 1000000000*toDec;
    
    enum State { BeforeSale, preSale, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;
    uint256 public accumulated = 0;


  

    address[7] public wallets;

    uint256 public adminSum = 470000000*toDec;  
    uint256 public NigelFundSum = 400000000*toDec;  
    uint256 public teamSum = 100000000*toDec;  
    uint256 public advisor1Sum = 12000000*toDec;  
    uint256 public advisor2Sum = 12000000*toDec;  
    uint256 public advisor3Sum = 6000000*toDec;  

     

    uint256 public lockupPeriod = 360 * 1 days;  

    uint256 public presaleEndtime = 1529020800;
    uint256 public ICOEndTime = 1531612800;



    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    function KimeraTokenCrowdsale(
        address _admin,  
        address _NigelFund,
        address _team,
        address _advisor1,
        address _advisor2,
        address _advisor3,
        address _unsold)
    Crowdsale(
        now + 5,  
        ICOEndTime, 
        3333, 
        _admin
    )  
    public 
    {      
        wallets[0] = _admin;
        wallets[1] = _NigelFund;
        wallets[2] = _team;
        wallets[3] = _advisor1;
        wallets[4] = _advisor2;
        wallets[5] = _advisor3;
        wallets[6] = _unsold;
        owner = _admin;
        token.mint(wallets[0], adminSum);
        token.mint(wallets[1], NigelFundSum);
        token.mint(wallets[3], advisor1Sum);
        token.mint(wallets[4], advisor2Sum);
        token.mint(wallets[5], advisor3Sum);
    }

     
     
    function createTokenContract() internal returns (MintableToken) {
        return new KimeraToken();
    }


    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        var halfPercent = amount.div(200);
        var adminAmount = halfPercent.mul(197);
        var advisorAmount = halfPercent.mul(3);
        wallets[0].transfer(adminAmount);
        wallets[3].transfer(advisorAmount);
        var left = amount.sub(adminAmount).sub(advisorAmount);
        accumulated = accumulated.add(left);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }


    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        wallets[walletIndex] = newAddress;
    }

    function calculateCurrentRate(State stat) internal {
        if (stat == State.NormalSale) {
            rate = 1666;
        }
    }

    function buyTokensUpdateState() internal {
        var temp = state;
        if(temp == State.BeforeSale && now >= startTime) { temp = State.preSale; }
        if(temp == State.preSale && now >= presaleEndtime) { temp = State.NormalSale; }
        if((temp == State.preSale || temp == State.BeforeSale) && tokensLeft <= 250000000*toDec) { temp = State.NormalSale; }
        calculateCurrentRate(temp);
        require(temp != State.ShouldFinalize && temp != State.Lockup && temp != State.SaleOver);
        if(msg.value.mul(rate) >= tokensLeft) { temp = State.ShouldFinalize; }
        state = temp;
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            super.buyTokens(beneficiary);
        }
        tokensLeft = tokensLeft.sub(numTokens);
    }

    function lastTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokensForFullBuy = weiAmount.mul(rate); 
        uint256 tokensToReKimeraFor = tokensForFullBuy.sub(tokensLeft);
        uint256 tokensRemaining = tokensForFullBuy.sub(tokensToReKimeraFor);
        uint256 weiAmountToReKimera = tokensToReKimeraFor.div(rate);
        uint256 weiRemaining = weiAmount.sub(weiAmountToReKimera);
        
         
        weiRaised = weiRaised.add(weiRemaining);

        token.mint(beneficiary, tokensRemaining);

        TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);
        forwardFundsAmount(weiRemaining);
        refundAmount(weiAmountToReKimera);
    }

    function withdrawLockupTokens() canWithdrawLockup public {
        token.mint(wallets[2], teamSum);
        
        token.finishMinting();
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalizeUpdateState() internal {
        if(now > endTime) { state = State.ShouldFinalize; }
        if(tokensLeft == 0) { state = State.ShouldFinalize; }
    }

    function finalize() public {
        finalizeUpdateState();
        require (state == State.ShouldFinalize);

        finalization();
        Finalized();
    }

    function finalization() internal {
        endTime = block.timestamp;  
        token.mint(wallets[6], tokensLeft);  
        state = State.Lockup;
    }
    
}