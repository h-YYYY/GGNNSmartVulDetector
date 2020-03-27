pragma solidity ^0.4.16;
library SafeMath {
  function mul(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant public returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) constant public returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if(msg.sender == owner){
      _;
    }
    else{
      revert();
    }
  }


   
  function transferOwnership(address newOwner) onlyOwner public{
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    if(!mintingFinished){
      _;
    }
    else{
      revert();
    }
  }


   
  function mint(address _to, uint256 _amount) canMint internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0),_to,_amount);
    return true;
  }

   
  function finishMinting()  internal returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract GreenCoin is MintableToken{
	
	string public constant name = "Green Coin";
	string public constant symbol = "GREEN";
	uint8 public constant decimals = 18;
	uint256 public constant MaxSupply = 10**18*10**7 ;
	uint256 public _startTime = 0 ;
	
	function GreenCoin(){
	    mint(address(0x7704C758db402bB7B1c2BbadA8af43B6B758B794),4000*10**18);
	    mint(address(0xbb3465742ca0b93eea8ca9362f2c4bb6240bf942),1000*10**18);
		_startTime = block.timestamp ;
		owner = msg.sender;
	}
	
	function GetMaxEther() returns(uint256){
		return (MaxSupply.sub(totalSupply)).div(10000);
	}
	
	function IsICOOver() public constant returns(bool){
		
		if(mintingFinished){
			return true;	
		}
		return false;
	}
	
	function IsICONotStarted() public constant returns(bool){
		if(block.timestamp<_startTime){
			return true;
		}
		return false;
	}
	
	function () public payable{
		if(IsICOOver() || IsICONotStarted()){
			revert();
		}
		else{
			if(GetMaxEther()>msg.value){
				mint(msg.sender,msg.value*10000);
				owner.transfer(msg.value);
			}
			else{
				mint(msg.sender,GetMaxEther()*10000);
				owner.transfer(GetMaxEther());
				finishMinting();
				
			}
		}
	}
}