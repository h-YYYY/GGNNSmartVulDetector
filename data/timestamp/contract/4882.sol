pragma solidity 0.4.24;

 
contract ERC20Basic {
  function decimals() public view returns (uint);
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

contract TokenLocker is Ownable {
    
    ERC20 public token = ERC20(0x611171923b84185e9328827CFAaE6630481eCc7a);  
    
     
    uint256 public releaseTimeFund = 1537833600;  
    uint256 public releaseTimeTeamAdvisorsPartners = 1552348800;  
    
    address public ReserveFund = 0xC5fed49Be1F6c3949831a06472aC5AB271AF89BD;  
    uint public ReserveFundAmount = 18600000 ether;
    
    address public AdvisorsPartners = 0x5B5521E9D795CA083eF928A58393B8f7FF95e098;  
    uint public AdvisorsPartnersAmount = 3720000 ether;
    
    address public Team = 0x556dB38b73B97954960cA72580EbdAc89327808E;  
    uint public TeamAmount = 4650000 ether;
    
    function unlockFund () public onlyOwner {
        require(releaseTimeFund <= block.timestamp);
        require(ReserveFundAmount > 0);
        uint tokenBalance = token.balanceOf(this);
        require(tokenBalance >= ReserveFundAmount);
        
        if (token.transfer(ReserveFund, ReserveFundAmount)) {
            ReserveFundAmount = 0;
        }
    }
    
    function unlockTeamAdvisorsPartnersTokens () public onlyOwner {
        require(releaseTimeTeamAdvisorsPartners <= block.timestamp);
        require(AdvisorsPartnersAmount > 0);
        require(TeamAmount > 0);
        uint tokenBalance = token.balanceOf(this);
        require(tokenBalance >= AdvisorsPartnersAmount + TeamAmount);
        
        if (token.transfer(AdvisorsPartners, AdvisorsPartnersAmount)) {
            AdvisorsPartnersAmount = 0;
        }
        
        if (token.transfer(Team, TeamAmount)) {
            TeamAmount = 0;
        }
    }
}