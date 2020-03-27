pragma solidity ^0.4.24;

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
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

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

contract JobsBounty is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string public companyName;  
    string public jobPost;  
    uint public endDate;  
    
     
     
     
    address public INDToken = 0xf8e386eda857484f5a12e4b5daa9984e06e73705;
    
    constructor(string _companyName,
                string _jobPost,
                uint _endDate
                ) public{
        companyName = _companyName;
        jobPost = _jobPost ;
        endDate = _endDate;
    }
    
     
    function ownBalance() public view returns(uint256) {
        return ERC20(INDToken).balanceOf(this);
    }
    
    function payOutBounty(address _referrerAddress, address _candidateAddress) public onlyOwner nonReentrant returns(bool){
        uint256 individualAmounts = (ERC20(INDToken).balanceOf(this) / 100) * 50;
        
        assert(block.timestamp >= endDate);
         
        assert(ERC20(INDToken).transfer(_candidateAddress, individualAmounts));
        assert(ERC20(INDToken).transfer(_referrerAddress, individualAmounts));
        return true;    
    }
    
     
     
     
    function withdrawERC20Token(address anyToken) public onlyOwner nonReentrant returns(bool){
        assert(block.timestamp >= endDate);
        assert(ERC20(anyToken).transfer(owner, ERC20(anyToken).balanceOf(this)));        
        return true;
    }
    
     
     
    function withdrawEther() public nonReentrant returns(bool){
        if(address(this).balance > 0){
            owner.transfer(address(this).balance);
        }        
        return true;
    }
}