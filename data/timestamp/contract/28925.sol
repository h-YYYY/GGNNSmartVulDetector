pragma solidity ^0.4.17;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 
interface ERC20_Interface {
  function totalSupply() public constant returns (uint total_supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _amount) public returns (bool success);
  function transferFrom(address _from, address _to, uint _amount) public returns (bool success);
  function approve(address _spender, uint _amount) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint amount);
}

 
interface Factory_Interface {
  function createToken(uint _supply, address _party, bool _long, uint _start_date) public returns (address created, uint token_ratio);
  function payToken(address _party, address _token_add) public;
  function deployContract(uint _start_date) public payable returns (address created);
   function getBase() public view returns(address _base1, address base2);
  function getVariables() public view returns (address oracle_addr, uint swap_duration, uint swap_multiplier, address token_a_addr, address token_b_addr);
}


 
interface DRCT_Token_Interface {
  function addressCount(address _swap) public constant returns (uint count);
  function getHolderByIndex(uint _ind, address _swap) public constant returns (address holder);
  function getBalanceByIndex(uint _ind, address _swap) public constant returns (uint bal);
  function getIndexByAddress(address _owner, address _swap) public constant returns (uint index);
  function createToken(uint _supply, address _owner, address _swap) public;
  function pay(address _party, address _swap) public;
  function partyCount(address _swap) public constant returns(uint count);
}


 
interface Oracle_Interface{
  function RetrieveData(uint _date) public view returns (uint data);
}


 
contract TokenToTokenSwap {

  using SafeMath for uint256;

   
   
  enum SwapState {
    created,
    open,
    started,
    tokenized,
    ready,
    ended
  }

   

   
  address creator;
   
  address oracle_address;
  Oracle_Interface oracle;

   
  address public factory_address;
  Factory_Interface factory;

   
  address public long_party;
  address public short_party;

   
  SwapState public current_state;

   
  uint start_date;
  uint end_date;

   
  uint multiplier;

   
  uint share_long;
  uint share_short;

   
  uint pay_to_short_a;
  uint pay_to_long_a;
  uint pay_to_long_b;
  uint pay_to_short_b;

   
  address long_token_address;
  address short_token_address;

   
  uint num_DRCT_longtokens;
  uint num_DRCT_shorttokens;

   
  address token_a_address;
  address token_b_address;

   
  ERC20_Interface token_a;
  ERC20_Interface token_b;

   
  uint public token_a_amount;
  uint public token_b_amount;

  uint public premium;

   
  address token_a_party;
  address token_b_party;

   
  uint duration;
   
  uint enterDate;
  DRCT_Token_Interface token;
  address userContract;

   

   
  event SwapCreation(address _token_a, address _token_b, uint _start_date, uint _end_date, address _creating_party);
   
  event PaidOut(address _long_token, address _short_token);

   

   
  modifier onlyState(SwapState expected_state) {
    require(expected_state == current_state);
    _;
  }

   

   
  function TokenToTokenSwap (address _factory_address, address _creator, address _userContract, uint _start_date) public {
    current_state = SwapState.created;
    creator =_creator;
    factory_address = _factory_address;
    userContract = _userContract;
    start_date = _start_date;
  }


   
  function showPrivateVars() public view returns (address _userContract, uint num_DRCT_long, uint numb_DRCT_short, uint swap_share_long, uint swap_share_short, address long_token_addr, address short_token_addr, address oracle_addr, address token_a_addr, address token_b_addr, uint swap_multiplier, uint swap_duration, uint swap_start_date, uint swap_end_date){
    return (userContract, num_DRCT_longtokens, num_DRCT_shorttokens,share_long,share_short,long_token_address,short_token_address, oracle_address, token_a_address, token_b_address, multiplier, duration, start_date, end_date);
  }

   
  function CreateSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) payable public onlyState(SwapState.created) {

    require(
      msg.sender == creator || (msg.sender == userContract && _senderAdd == creator)
    );
    factory = Factory_Interface(factory_address);
    setVars();
    end_date = start_date.add(duration.mul(86400));
    token_a_amount = _amount_a;
    token_b_amount = _amount_b;

    premium = this.balance;
    token_a = ERC20_Interface(token_a_address);
    token_a_party = _senderAdd;
    if (_sender_is_long)
      long_party = _senderAdd;
    else
      short_party = _senderAdd;
    current_state = SwapState.open;
  }

  function setVars() internal{
      (oracle_address,duration,multiplier,token_a_address,token_b_address) = factory.getVariables();
  }

   
  function EnterSwap(
    uint _amount_a,
    uint _amount_b,
    bool _sender_is_long,
    address _senderAdd
    ) public onlyState(SwapState.open) {

     
    require(
      token_a_amount == _amount_a &&
      token_b_amount == _amount_b &&
      token_a_party != _senderAdd
    );

    token_b = ERC20_Interface(token_b_address);
    token_b_party = _senderAdd;

     
    if (_sender_is_long) {
      require(long_party == 0);
      long_party = _senderAdd;
    } else {
      require(short_party == 0);
      short_party = _senderAdd;
    }

    SwapCreation(token_a_address, token_b_address, start_date, end_date, token_b_party);
    enterDate = now;
    current_state = SwapState.started;
  }

   
  function createTokens() public onlyState(SwapState.started){

     
    require(
      now < (enterDate + 86400) &&
      token_a.balanceOf(address(this)) >= token_a_amount &&
      token_b.balanceOf(address(this)) >= token_b_amount
    );

    uint tokenratio = 1;
    (long_token_address,tokenratio) = factory.createToken(token_a_amount, long_party,true,start_date);
    num_DRCT_longtokens = token_a_amount.div(tokenratio);
    (short_token_address,tokenratio) = factory.createToken(token_b_amount, short_party,false,start_date);
    num_DRCT_shorttokens = token_b_amount.div(tokenratio);
    current_state = SwapState.tokenized;
    if (premium > 0){
      if (creator == long_party){
      short_party.transfer(premium);
      }
      else {
        long_party.transfer(premium);
      }
    }
  }

   
  function Calculate() internal {
    require(now >= end_date + 86400);
     
    oracle = Oracle_Interface(oracle_address);
    uint start_value = oracle.RetrieveData(start_date);
    uint end_value = oracle.RetrieveData(end_date);

    uint ratio;
    if (start_value > 0 && end_value > 0)
      ratio = (end_value).mul(100000).div(start_value);
    else if (end_value > 0)
      ratio = 10e10;
    else if (start_value > 0)
      ratio = 0;
    else
      ratio = 100000;
    if (ratio == 100000) {
      share_long = share_short = ratio;
    } else if (ratio > 100000) {
      share_long = ((ratio).sub(100000)).mul(multiplier).add(100000);
      if (share_long >= 200000)
        share_short = 0;
      else
        share_short = 200000-share_long;
    } else {
      share_short = SafeMath.sub(100000,ratio).mul(multiplier).add(100000);
       if (share_short >= 200000)
        share_long = 0;
      else
        share_long = 200000- share_short;
    }

     
    calculatePayout();

    current_state = SwapState.ready;
  }

   
  function calculatePayout() internal {
    uint ratio;
    token_a_amount = token_a_amount.mul(995).div(1000);
    token_b_amount = token_b_amount.mul(995).div(1000);
     
    if (share_long == 100000) {
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_b = 0;
      pay_to_long_a = 0;
    } else if (share_long > 100000) {
      ratio = SafeMath.min(100000, (share_long).sub(100000));
      pay_to_long_b = (token_b_amount).div(num_DRCT_shorttokens);
      pay_to_short_a = (SafeMath.sub(100000,ratio)).mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_long_a = ratio.mul(token_a_amount).div(num_DRCT_longtokens).div(100000);
      pay_to_short_b = 0;
    } else {
      ratio = SafeMath.min(100000, (share_short).sub(100000));
      pay_to_short_a = (token_a_amount).div(num_DRCT_longtokens);
      pay_to_long_b = (SafeMath.sub(100000,ratio)).mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_short_b = ratio.mul(token_b_amount).div(num_DRCT_shorttokens).div(100000);
      pay_to_long_a = 0;
    }
  }

   
  function forcePay(uint _begin, uint _end) public returns (bool) {
     
    if(current_state == SwapState.tokenized  ){
      Calculate();
    }

     
    require(current_state == SwapState.ready);

     

    token = DRCT_Token_Interface(long_token_address);
    uint count = token.addressCount(address(this));
    uint loop_count = count < _end ? count : _end;
     
    for(uint i = loop_count-1; i >= _begin ; i--) {
      address long_owner = token.getHolderByIndex(i, address(this));
      uint to_pay_long = token.getBalanceByIndex(i, address(this));
      paySwap(long_owner, to_pay_long, true);
    }

    token = DRCT_Token_Interface(short_token_address);
    count = token.addressCount(address(this));
    loop_count = count < _end ? count : _end;
    for(uint j = loop_count-1; j >= _begin ; j--) {
      address short_owner = token.getHolderByIndex(j, address(this));
      uint to_pay_short = token.getBalanceByIndex(j, address(this));
      paySwap(short_owner, to_pay_short, false);
    }

    if (loop_count == count){
        token_a.transfer(factory_address, token_a.balanceOf(address(this)));
        token_b.transfer(factory_address, token_b.balanceOf(address(this)));
        PaidOut(long_token_address, short_token_address);
        current_state = SwapState.ended;
      }
    return true;
  }

   
  function paySwap(address _receiver, uint _amount, bool _is_long) internal {
    if (_is_long) {
      if (pay_to_long_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_long_a));
      if (pay_to_long_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_long_b));
      }
        factory.payToken(_receiver,long_token_address);
    } else {

      if (pay_to_short_a > 0)
        token_a.transfer(_receiver, _amount.mul(pay_to_short_a));
      if (pay_to_short_b > 0){
        token_b.transfer(_receiver, _amount.mul(pay_to_short_b));
      }
       factory.payToken(_receiver,short_token_address);
    }
  }


   
  function Exit() public {
   if (current_state == SwapState.open && msg.sender == token_a_party) {
      token_a.transfer(token_a_party, token_a_amount);
      if (premium>0){
        msg.sender.transfer(premium);
      }
      delete token_a_amount;
      delete token_b_amount;
      delete premium;
      current_state = SwapState.created;
    } else if (current_state == SwapState.started && (msg.sender == token_a_party || msg.sender == token_b_party)) {
      if (msg.sender == token_a_party || msg.sender == token_b_party) {
        token_b.transfer(token_b_party, token_b.balanceOf(address(this)));
        token_a.transfer(token_a_party, token_a.balanceOf(address(this)));
        current_state = SwapState.ended;
        if (premium > 0) { creator.transfer(premium);}
      }
    }
  }
}


 
contract Deployer {
  address owner;
  address factory;

  function Deployer(address _factory) public {
    factory = _factory;
    owner = msg.sender;
  }

  function newContract(address _party, address user_contract, uint _start_date) public returns (address created) {
    require(msg.sender == factory);
    address new_contract = new TokenToTokenSwap(factory, _party, user_contract, _start_date);
    return new_contract;
  }

   function setVars(address _factory, address _owner) public {
    require (msg.sender == owner);
    factory = _factory;
    owner = _owner;
  }
}