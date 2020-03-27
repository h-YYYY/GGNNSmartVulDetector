pragma solidity ^0.4.18;  

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract Halo3D {

    function buy(address) public payable returns(uint256);
    function transfer(address, uint256) public returns(bool);
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function reinvest() public;
}

 
contract AcceptsHalo3D {
    Halo3D public tokenContract;

    function AcceptsHalo3D(address _tokenContract) public {
        tokenContract = Halo3D(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Halo3DPotPotato is AcceptsHalo3D {
    address public ceoAddress;
    address public hotPotatoHolder;
    address public lastHotPotatoHolder;
    uint256 public lastBidTime;
    uint256 public contestStartTime;
    uint256 public lastPot;

    Potato[] public potatoes;

    uint256 public BASE_TIME_TO_COOK=30 minutes; 
    uint256 public TIME_MULTIPLIER=5 minutes; 
    uint256 public TIME_TO_COOK=BASE_TIME_TO_COOK;  
    uint256 public NUM_POTATOES=12;
    uint256 public START_PRICE=10 ether;  
    uint256 public CONTEST_INTERVAL= 1 days; 

     
    struct Potato {
        address owner;
        uint256 price;
    }

     
    function Halo3DPotPotato(address _baseContract)
      AcceptsHalo3D(_baseContract)
      public{
        ceoAddress=msg.sender;
        hotPotatoHolder=0;
        contestStartTime=now;
        for(uint i = 0; i<NUM_POTATOES; i++){
            Potato memory newpotato=Potato({owner:address(this),price: START_PRICE});
            potatoes.push(newpotato);
        }
    }
    
      
    function() payable public {
       
       
    }

     
     
    function tokenFallback(address _from, uint256 _value, bytes _data)
      external
      onlyTokenContract
      returns (bool) {
        require(now > contestStartTime);
        require(!_isContract(_from));
        if(_endContestIfNeeded(_from, _value)){

        }
        else{
             
            uint64 index = uint64(_data[0]);
            Potato storage potato=potatoes[index];
            require(_value >= potato.price);
             
            require(_from != potato.owner);
            require(_from != ceoAddress);
            uint256 sellingPrice=potato.price;
            uint256 purchaseExcess = SafeMath.sub(_value, sellingPrice);
            uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 76), 100));
            uint256 devFee= uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));
             
             
            reinvest();
            if(potato.owner!=address(this)){
                tokenContract.transfer(potato.owner, payment);
            }
            tokenContract.transfer(ceoAddress, devFee);
            potato.price= SafeMath.div(SafeMath.mul(sellingPrice, 150), 76);
            potato.owner=_from; 
            hotPotatoHolder=_from; 
            lastBidTime=now;
            TIME_TO_COOK=SafeMath.add(BASE_TIME_TO_COOK,SafeMath.mul(index,TIME_MULTIPLIER));  

            tokenContract.transfer(_from, purchaseExcess);  
        }

        return true;
    }


     
     
     
    function reinvest() public {
       if(tokenContract.myDividends(true) > 1) {
         tokenContract.reinvest();
       }
          
    }

     
    function getContractDividends() public view returns(uint256) {
      return tokenContract.myDividends(true);  
    }

     
    function getBalance() public view returns(uint256 value){
        return tokenContract.myTokens();
    }

    function timePassed() public view returns(uint256 time){
        if(lastBidTime==0){
            return 0;
        }
        return SafeMath.sub(block.timestamp,lastBidTime);
    }

    function timeLeftToContestStart() public view returns(uint256 time){
        if(block.timestamp>contestStartTime){
            return 0;
        }
        return SafeMath.sub(contestStartTime,block.timestamp);
    }

    function timeLeftToCook() public view returns(uint256 time){
        return SafeMath.sub(TIME_TO_COOK,timePassed());
    }

    function contestOver() public view returns(bool){
        return timePassed()>=TIME_TO_COOK;
    }

     
     
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
    }

    function _endContestIfNeeded(address _from, uint256 _value) private returns(bool){
        if(timePassed()>=TIME_TO_COOK){
             
            reinvest();
            tokenContract.transfer(_from, _value);
            lastPot=getBalance();
            lastHotPotatoHolder=hotPotatoHolder;
            tokenContract.transfer(hotPotatoHolder, tokenContract.myTokens());
            hotPotatoHolder=0;
            lastBidTime=0;
            _resetPotatoes();
            _setNewStartTime();
            return true;
        }
        return false;
    }

    function _resetPotatoes() private{
        for(uint i = 0; i<NUM_POTATOES; i++){
            Potato memory newpotato=Potato({owner:address(this),price: START_PRICE});
            potatoes[i]=newpotato;
        }
    }

    function _setNewStartTime() private{
        uint256 start=contestStartTime;
        while(start < now){
            start=SafeMath.add(start,CONTEST_INTERVAL);
        }
        contestStartTime=start;
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