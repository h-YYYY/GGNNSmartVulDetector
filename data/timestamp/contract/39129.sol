 
library SafeMathLib {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) private {
    if (!assertion) throw;
  }
}




 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


 
contract PricingStrategy {

   
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

   
  function calculatePrice(uint value, uint tokensSold, uint weiRaised, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}


 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane() public constant returns (bool);

   
  function finalizeCrowdsale();

}




 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract FractionalERC20 is ERC20 {

  uint public decimals;

}



 
contract Crowdsale is Haltable {

  using SafeMathLib for uint;

   
  FractionalERC20 public token;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  bool public requireCustomerId;

   
  bool public requiredSignedAddress;

   
  address public signerAddress;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint weiAmount);

   
  event InvestmentPolicyChanged(bool requireCustomerId, bool requiredSignedAddress, address signerAddress);

   
  event Whitelisted(address addr, bool status);

   
  event EndsAtChanged(uint endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {

    if(_minimumFundingGoal != 0) {
       
    }

    owner = msg.sender;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

     
    if(startsAt >= endsAt) {
        throw;
    }

  }

   
  function() payable {
    throw;
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

     
    if(getState() == State.PreFunding) {
       
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
       
       
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
       
      throw;
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

     
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

     
    if(isBreakingCap(tokenAmount, weiAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

     
    if(!multisigWallet.send(weiAmount)) throw;

     
    Invested(receiver, weiAmount, tokenAmount, customerId);

     
    onInvest();
  }

   
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw;  
    if(customerId == 0) throw;   
    investInternal(addr, customerId);
  }

   
  function invest(address addr) public payable {
    if(requireCustomerId) throw;  
    if(requiredSignedAddress) throw;  
    investInternal(addr, 0);
  }

   
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

     
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

   
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

     
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = loadedRefund.plus(msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

   
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

   
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }


   
  function onInvest() internal {

  }

   
   
   

   
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }

   
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw;  
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) private;
}







 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



 
contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function addApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = safeAdd(oldValue, _addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

   
  function subApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2 * 32)
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = safeSub(oldVal, _subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

}





 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
         
        throw;
      }

       
      if (value == 0) throw;

      balances[msg.sender] = safeSub(balances[msg.sender], value);

       
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
         
        throw;
      }

      if (agent == 0x0) throw;
       
      if (msg.sender != upgradeMaster) throw;
       
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

       
      if(!upgradeAgent.isUpgradeAgent()) throw;
       
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}






 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}







 
contract MintableToken is StandardToken, Ownable {

  using SafeMathLib for uint;

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {

    if(amount == 0) {
      throw;
    }

    totalSupply = totalSupply.plus(amount);
    balances[receiver] = balances[receiver].plus(amount);
    Minted(receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
  }

  modifier onlyMintAgent() {
     
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }

   
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }
}




 
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

   
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals)
    UpgradeableToken(msg.sender) {

     
     
     
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

     
    balances[owner] = totalSupply;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public constant returns(bool) {
    return released;
  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}








 
contract MysteriumPricing is PricingStrategy, Ownable {

  using SafeMathLib for uint;

   
   
   
  uint public chfRate;

  uint public chfScale = 10000;

   
  uint public hardCapPrice = 12000;   

  uint public softCapPrice = 10000;   

  uint public softCapCHF = 6000000 * 10000;  

   
  Crowdsale public crowdsale;

  function MysteriumPricing(uint initialChfRate) {
    chfRate = initialChfRate;
  }

   
   
  function setCrowdsale(Crowdsale _crowdsale) onlyOwner {

    if(!_crowdsale.isCrowdsale()) {
      throw;
    }

    crowdsale = _crowdsale;
  }

   
   
  function setConversionRate(uint _chfRate) onlyOwner {
     
    if(now > crowdsale.startsAt())
      throw;

    chfRate = _chfRate;
  }

   
  function setSoftCapCHF(uint _softCapCHF) onlyOwner {
    softCapCHF = _softCapCHF;
  }

   
  function getEthChfPrice() public constant returns (uint) {
    return chfRate / chfScale;
  }

   
  function convertToWei(uint chf) public constant returns(uint) {
    return chf.times(10**18) / chfRate;
  }

   
  function getSoftCapInWeis() public returns (uint) {
    return convertToWei(softCapCHF);
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {

    uint multiplier = 10 ** decimals;
    if (weiRaised > getSoftCapInWeis()) {
       
      return value.times(multiplier) / convertToWei(hardCapPrice);
    } else {
      return value.times(multiplier) / convertToWei(softCapPrice);
    }
  }

}



 
contract MysteriumTokenDistribution is FinalizeAgent, Ownable {

  using SafeMathLib for uint;

  CrowdsaleToken public token;
  Crowdsale public crowdsale;

  MysteriumPricing public mysteriumPricing;

   
  address futureRoundVault;
  address foundationWallet;
  address teamVault;
  address seedVault1;  
  address seedVault2;  

   
  uint SOFT_CAP_CHF = 6000000;
  uint MIN_SOFT_CAP_CHF = 2000000;
  uint SEED_RAISED_ETH = 6000;
  uint FOUNDATION_PERCENTAGE = 9;
  uint TEAM_PERCENTAGE = 10;
   
  uint REGULAR_PRICE_MULTIPLIER = 1;
  uint multiplier = 10 ** 8;

   
  uint public earlybird_coins;
  uint public regular_coins;
  uint public seed_coins;
  uint public total_coins;
  uint public future_round_coins;
  uint public foundation_coins;
  uint public team_coins;
  uint public seed_coins_vault1;
  uint public seed_coins_vault2;
  uint public seed_multiplier;
  uint public future_round_percentage;
  uint public percentage_of_three;
  uint public earlybird_percentage;

  function MysteriumTokenDistribution(CrowdsaleToken _token, Crowdsale _crowdsale, MysteriumPricing _mysteriumPricing) {
    token = _token;
    crowdsale = _crowdsale;

     
    if(!crowdsale.isCrowdsale()) {
      throw;
    }

    mysteriumPricing = _mysteriumPricing;
  }

   
  function distribute(uint amount_raised_chf, uint eth_chf_price) {

     
    if(!(msg.sender == address(crowdsale) || msg.sender == owner)) {
      throw;
    }

     
     
     
     

     
    if (amount_raised_chf <= SOFT_CAP_CHF) {
       earlybird_coins = amount_raised_chf.times(multiplier).plus(amount_raised_chf.times(multiplier)/5);
    }
    else {
      earlybird_coins = SOFT_CAP_CHF.times(multiplier).plus(SOFT_CAP_CHF.times(multiplier)/5);
    }

     
    regular_coins = 0;
    if (amount_raised_chf > SOFT_CAP_CHF) {
      regular_coins = (amount_raised_chf.minus(SOFT_CAP_CHF)).times(multiplier).times(REGULAR_PRICE_MULTIPLIER);
    }

     
     
     
    if (amount_raised_chf <= MIN_SOFT_CAP_CHF) {
        seed_multiplier = multiplier.times(1);
    } else if (amount_raised_chf > MIN_SOFT_CAP_CHF && amount_raised_chf < SOFT_CAP_CHF) {
        seed_multiplier = ((amount_raised_chf / 1000000).minus(1)).times(multiplier);

    } else   {
        seed_multiplier = multiplier.times(5);
    }

     
    seed_coins = SEED_RAISED_ETH.times(eth_chf_price).times(seed_multiplier);

     
     
     
    if (amount_raised_chf <= MIN_SOFT_CAP_CHF) {
        future_round_percentage = multiplier.times(50);
    } else if (amount_raised_chf > MIN_SOFT_CAP_CHF && amount_raised_chf < SOFT_CAP_CHF) {
       future_round_percentage = uint(6750000000).minus((amount_raised_chf / 1000000).times(875000000));
    } else if (amount_raised_chf >= SOFT_CAP_CHF) {
        future_round_percentage = multiplier.times(15);
    }

     
     
    percentage_of_three = multiplier.times(100).minus(multiplier.times(FOUNDATION_PERCENTAGE)).minus(multiplier.times(TEAM_PERCENTAGE)).minus(future_round_percentage);

     
    earlybird_percentage = earlybird_coins.times(percentage_of_three) / (earlybird_coins.plus(regular_coins).plus(seed_coins));

     
    total_coins = multiplier.times(100).times(earlybird_coins) / earlybird_percentage;


     
    future_round_coins = future_round_percentage.times(total_coins) / 100 / multiplier;

     
    foundation_coins = FOUNDATION_PERCENTAGE.times(total_coins) / 100;

     
    team_coins = TEAM_PERCENTAGE.times(total_coins) / 100;

     

     
    seed_coins_vault1 = (seed_coins / seed_multiplier).times(multiplier);

     
    seed_coins_vault2 = seed_coins.minus((seed_coins / seed_multiplier).times(multiplier));

     
     


    if(future_round_coins > 0) {
      token.mint(futureRoundVault, future_round_coins);
    }

    if(foundation_coins > 0) {
      token.mint(foundationWallet, foundation_coins);
    }

    if(team_coins > 0) {
      token.mint(teamVault, team_coins);
    }

    if(seed_coins_vault1 > 0) {
      token.mint(seedVault1, seed_coins_vault1);
    }

    if(seed_coins_vault2 > 0) {
      token.mint(seedVault2, seed_coins_vault2);
    }

     
     
     
     
     
     
     
     
     
     
  }

   
  function setVaults(
    address _futureRoundVault,
    address _foundationWallet,
    address _teamVault,
    address _seedVault1,
    address _seedVault2
  ) onlyOwner {
    futureRoundVault = _futureRoundVault;
    foundationWallet = _foundationWallet;
    teamVault = _teamVault;
    seedVault1 = _seedVault1;
    seedVault2 = _seedVault2;
  }

   
  function isSane() public constant returns (bool) {
     
    return true;
  }

  function getDistributionFacts() public constant returns (uint chfRaised, uint chfRate) {
    uint _chfRate = mysteriumPricing.getEthChfPrice();
    return(crowdsale.weiRaised().times(_chfRate) / (10**18), _chfRate);
  }

   
  function finalizeCrowdsale() public {

    if(msg.sender == address(crowdsale) || msg.sender == owner) {
       
       
      var (chfRaised, chfRate) = getDistributionFacts();
      distribute(chfRaised, chfRate);
    } else {
       throw;
    }
  }

}