pragma solidity ^0.4.21;

 

 

 

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Serpent is Ownable {
	using SafeMath for uint256;

	 
	mapping (address => uint256) public investorReturn;

	uint256 public SerpenSegmentCount;
	uint256 public SerpentCountDown;
	address public SerpentHead;
	address[] investormapping;

	struct investorDetails {
	    address investorAddress;
	    uint256 amountInvested;
	    uint256 SegmentNumber;
	    uint256 time;
	    string  quote;
	}

	investorDetails[] public investorsList;

	function Serpent () {
		 
		SerpentHead = owner;
		SerpenSegmentCount = 0;
		SerpentCountDown = uint256(block.timestamp);
	}

	function Play (string _quote) payable public {

		require (msg.value > 0);
        require (msg.sender != address(0));  
        require (uint256(block.timestamp) < SerpentCountDown);  

        address thisAddress = msg.sender;
		uint256 thisAmmount = msg.value;

        AddReturnsMapping(thisAmmount);
	     

	    SerpenSegmentCount = SerpenSegmentCount.add(1);
		AddNewSegment(thisAddress, thisAmmount, SerpenSegmentCount, uint256(block.timestamp), _quote);
	     
         
	}

	 
	function () payable public {
		require(msg.value > 0);

		Play("Callback, No quote");
	}

	function NewSerpent (uint256 _SerpentCountDown) public onlyOwner {

		 
		require (uint256(block.timestamp) > SerpentCountDown);
		
		SerpenSegmentCount = 0;
		SerpentCountDown = _SerpentCountDown;

		 
		uint256 nonPrimeReminders = 0;
		for (uint256 p = 0; p < investormapping.length; p++) {
			nonPrimeReminders.add(investorReturn[investormapping[p]]);
		}
		uint256 PrimeReminder = uint256(address(this).balance) - nonPrimeReminders;
		SerpentHead.transfer(PrimeReminder);

		 
		while (investormapping.length != 0) {
			delete investormapping[investormapping.length-1];  
			investormapping.length--;
		}

		 
	    SerpenSegmentCount = SerpenSegmentCount.add(1);
	    investormapping.push(SerpentHead);
	    AddNewSegment(SerpentHead, 1 ether, SerpenSegmentCount, uint256(block.timestamp), "Everything started with Salazar Slytherin");
	}
	
	
	function AddNewSegment (address _address, uint256 _amount, uint256 _segmentNumber, uint256 _time, string _quote) internal {
	    require (_amount > 0);  

		 
		uint256 inList = 0;
		for (uint256 n = 0; n < investormapping.length; n++) {
			if (investormapping[n] == _address) {
				inList = 1;
			}
		}
		if (inList == 0) {
			investorReturn[_address] = 0;
			investormapping.push(_address);  
		}

		 
		investorsList.push(investorDetails(_address, _amount, _segmentNumber, _time, _quote));
	}

	function AddReturnsMapping (uint256 _amount) internal {

		uint256 individualAmount = _amount.div(investormapping.length);

		for (uint256 a = 0; a < investormapping.length; a++) {
			investorReturn[investormapping[a]] = investorReturn[investormapping[a]].add(individualAmount); 
		}
	}
	
	function CollectReturns () external {

		uint256 currentTime = uint256(block.timestamp);
		uint256 amountToCollect = getReturns(msg.sender);
		require (currentTime > SerpentCountDown);  
		require(address(this).balance >= amountToCollect);

		address(msg.sender).transfer(amountToCollect);
		investorReturn[msg.sender] = 0;
	}

	function getBalance () public view returns(uint256) {
		return uint256(address(this).balance);
	}

	function getParticipants () public view returns(uint256) {
		return uint256(investormapping.length);
	}

	function getCountdownDate () public view returns(uint256) {
		return uint256(SerpentCountDown);
	}

	function getReturns (address _address) public view returns(uint256) {
		return uint256(investorReturn[_address]);
	}
	
	function SerpentIsRunning () public view returns(bool) {
		return bool(uint256(block.timestamp) < SerpentCountDown);
	}

   
}