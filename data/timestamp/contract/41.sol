pragma solidity 0.4.24;

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


 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


interface DisbursementHandlerI {
    function withdraw(address _beneficiary, uint256 _index) external;
}


 
contract DisbursementHandler is DisbursementHandlerI, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Disbursement {
         
        uint256 timestamp;

         
        uint256 value;
    }

    event Setup(address indexed _beneficiary, uint256 _timestamp, uint256 _value);
    event TokensWithdrawn(address indexed _to, uint256 _value);

    ERC20 public token;
    uint256 public totalAmount;
    mapping(address => Disbursement[]) public disbursements;

    constructor(ERC20 _token) public {
        require(_token != address(0));
        token = _token;
    }

     
     
     
     
    function setupDisbursement(
        address _beneficiary,
        uint256 _value,
        uint256 _timestamp
    )
        external
        onlyOwner
    {
        require(block.timestamp < _timestamp);
        disbursements[_beneficiary].push(Disbursement(_timestamp, _value));
        totalAmount = totalAmount.add(_value);
        emit Setup(_beneficiary, _timestamp, _value);
    }

     
     
     
    function withdraw(address _beneficiary, uint256 _index)
        external
    {
        Disbursement[] storage beneficiaryDisbursements = disbursements[_beneficiary];
        require(_index < beneficiaryDisbursements.length);

        Disbursement memory disbursement = beneficiaryDisbursements[_index];
        require(disbursement.timestamp < now && disbursement.value > 0);

         
        delete beneficiaryDisbursements[_index];

        token.safeTransfer(_beneficiary, disbursement.value);
        emit TokensWithdrawn(_beneficiary, disbursement.value);
    }
}