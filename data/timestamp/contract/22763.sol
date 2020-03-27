pragma solidity ^0.4.8;

 
 
contract ERC20 {
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Capsule {
     
     
    address public recipient;
     
    uint public excavation;
     
    address public company = 0x46D99c89AE7529DDBAC80BEA2e8Ae017471Fc630;
     
    uint public percent = 2;

     
    event CapsuleCreated(
        uint _excavation,
        address _recipient
    );

     
     
     
    function Capsule(uint _excavation, address _recipient) payable public {
      require(_excavation < (block.timestamp + 100 years));
      recipient = _recipient;
      excavation = _excavation;
      CapsuleCreated(_excavation, _recipient);
    }

     
    event Deposit(
        uint _amount,
        address _sender
    );

     
     
    function () payable public {
      Deposit(msg.value, msg.sender);
    }

     
    event EtherWithdrawal(
      uint _amount
    );

     
    event TokenWithdrawal(
      address _tokenAddress,
      uint _amount
    );

     
     
    function withdraw(address[] _tokens) public {
      require(msg.sender == recipient);
      require(block.timestamp > excavation);

       
      if(this.balance > 0) {
        uint ethShare = this.balance / (100 / percent);
        company.transfer(ethShare);
        uint ethWithdrawal = this.balance;
        msg.sender.transfer(ethWithdrawal);
        EtherWithdrawal(ethWithdrawal);
      }

       
      for(uint i = 0; i < _tokens.length; i++) {
        ERC20 token = ERC20(_tokens[i]);
        uint tokenBalance = token.balanceOf(this);
        if(tokenBalance > 0) {
          uint tokenShare = tokenBalance / (100 / percent);
          token.transfer(company, tokenShare);
          uint tokenWithdrawal = token.balanceOf(this);
          token.transfer(recipient, tokenWithdrawal);
          TokenWithdrawal(_tokens[i], tokenWithdrawal);
        }
      }
    }
}