pragma solidity ^0.4.4;

 

contract ERC223Token {
  function transfer(address _from, uint _value, bytes _data) public;
}

contract Operations {

  mapping (address => uint) public balances;
  mapping (address => bytes32) public activeCall;

   
  mapping (bytes32 => address) public recipientsMap;

  mapping (address => uint) public endCallRequestDate;

  uint endCallRequestDelay = 1 hours;

  ERC223Token public exy;

  function Operations() public {
    exy = ERC223Token(0xFA74F89A6d4a918167C51132614BbBE193Ee8c22);
  }

   
  function tokenFallback(address _from, uint _value, bytes _data) public {
    balances[_from] += _value;
  }

  function withdraw(uint value) public {
     
    require(activeCall[msg.sender] == 0x0);

    uint balance = balances[msg.sender];

     
    require(value <= balance);

    balances[msg.sender] -= value;
    bytes memory empty;
    exy.transfer(msg.sender, value, empty);
  }

  function startCall(uint timestamp, uint8 _v, bytes32 _r, bytes32 _s) public {
     
    address recipient = msg.sender;
    bytes32 callHash = keccak256('Experty.io startCall:', recipient, timestamp);
    address caller = ecrecover(callHash, _v, _r, _s);

     
    require(activeCall[caller] == 0x0);

     
    activeCall[caller] = callHash;
    recipientsMap[callHash] = recipient;

     
     
    endCallRequestDate[caller] = 0;
  }

  function endCall(bytes32 callHash, uint amount, uint8 _v, bytes32 _r, bytes32 _s) public {
     
    address recipient = recipientsMap[callHash];

     
    require(recipient == msg.sender);

    bytes32 endHash = keccak256('Experty.io endCall:', recipient, callHash, amount);
    address caller = ecrecover(endHash, _v, _r, _s);

     
    require(activeCall[caller] == callHash);

    uint maxAmount = amount;
    if (maxAmount > balances[caller]) {
      maxAmount = balances[caller];
    }

     
    recipientsMap[callHash] = 0x0;
     
    activeCall[caller] = 0x0;

    settlePayment(caller, msg.sender, maxAmount);
  }

   
   
  function requestEndCall() public {
     
    require(activeCall[msg.sender] != 0x0);

     
    endCallRequestDate[msg.sender] = block.timestamp;
  }

   
   
  function forceEndCall() public {
     
    require(activeCall[msg.sender] != 0x0);
     
    require(endCallRequestDate[msg.sender] != 0);
    require(endCallRequestDate[msg.sender] + endCallRequestDelay < block.timestamp);

    endCallRequestDate[msg.sender] = 0;

     
    recipientsMap[activeCall[msg.sender]] = 0x0;
     
    activeCall[msg.sender] = 0x0;
  }

  function settlePayment(address sender, address recipient, uint value) private {
    balances[sender] -= value;
    balances[recipient] += value;
  }

}