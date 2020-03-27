pragma solidity ^0.4.16;

interface Token3DAPP {
    function transfer(address receiver, uint amount);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

contract PreSale3DAPP is Pausable {
    using SafeMath for uint256;

    Token3DAPP public tokenReward; 
    uint256 public deadline;

    uint256 public tokenPrice = 10000;  
    uint256 public minimalETH = 200000000000000000;  

    function PreSale3DAPP(address _tokenReward) {
        tokenReward = Token3DAPP(_tokenReward);  
        deadline = block.timestamp.add(2 weeks); 
    }

    function () whenNotPaused payable {
        buy(msg.sender);
    }

    function buy(address buyer) whenNotPaused payable {
        require(buyer != address(0));
        require(msg.value != 0);
        require(msg.value >= minimalETH);

        uint amount = msg.value;
        uint tokens = amount.mul(tokenPrice);
        tokenReward.transfer(buyer, tokens);
    }

    function transferFund() onlyOwner {
        owner.transfer(this.balance);
    }

    function updatePrice(uint256 _tokenPrice) onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function updateMinimal(uint256 _minimalETH) onlyOwner {
        minimalETH = _minimalETH;
    }

    function transferTokens(uint256 _tokens) onlyOwner {
        tokenReward.transfer(owner, _tokens); 
    }

     
    function airdrop(address[] _array1, uint256[] _array2) onlyOwner {
       address[] memory arrayAddress = _array1;
       uint256[] memory arrayAmount = _array2;
       uint256 arrayLength = arrayAddress.length.sub(1);
       uint256 i = 0;
       
       while (i <= arrayLength) {
           tokenReward.transfer(arrayAddress[i], arrayAmount[i]);
           i = i.add(1);
       }  
   }

}