 
 
pragma solidity ^0.4.17;

contract ERC20
{
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
      
     function transfer(address to, uint tokens) public returns (bool success);
      
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

contract TicketPro is ERC20
{
     
     
    uint totalTickets;
    mapping(address => uint) balances;
    uint expiryTimeStamp;
    address admin;
    uint transferFee;
    uint numOfTransfers = 0;
    string public name;
    string public symbol;
    string public date;
    string public venue;
    bytes32[] orderHashes;
    uint startPrice;
    uint limitOfStartTickets;
    uint8 public constant decimals = 0;  

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event TransferFrom(address indexed _from, address indexed _to, uint _value);

    modifier eventNotExpired()
    {
         
        if(block.timestamp > expiryTimeStamp)
        {
            revert();
        }
        else _;
    }

    modifier adminOnly()
    {
        if(msg.sender != admin) revert();
        else _;
    }

    function() public { revert(); }  

    function TicketPro(uint numberOfTickets, string evName, uint expiry,
            uint fee, string evDate, string evVenue, string eventSymbol,
             uint price, uint startTicketLimit) public
    {
        totalTickets = numberOfTickets;
         
        balances[msg.sender] = totalTickets;
        expiryTimeStamp = expiry;
        admin = msg.sender;
         
        transferFee = (1 ether * fee) / 100;
        symbol = eventSymbol;
        name = evName;
        date = evDate;
        venue = evVenue;
        startPrice = price;
        limitOfStartTickets= startTicketLimit;
    }

     
    function buyATicketFromContract(uint numberOfTickets) public payable returns (bool)
    {
         
        if(msg.value != startPrice * numberOfTickets
            || numberOfTickets % 1 != 0) revert();
        admin.transfer(msg.value);
        balances[msg.sender] += 1;
        return true;
    }

    function getTicketStartPrice() public view returns(uint)
    {
        return startPrice;
    }

    function getDecimals() public pure returns(uint)
    {
        return decimals;
    }

    function getNumberOfAvailableStartTickets() public view returns (uint)
    {
        return limitOfStartTickets;
    }

     
    function deliveryVSpayment(bytes32 offer, uint8 v, bytes32 r,
        bytes32 s) public payable returns(bool)
    {
	    var (seller, quantity, price, agreementIsValid) = recover(offer, v, r, s);
         
        uint cost = price * quantity;
        if(agreementIsValid && msg.value == cost)
        {
             
            balances[msg.sender] += uint(quantity);
            balances[seller] -= uint(quantity);
            uint commission = (msg.value / 100) * transferFee;
            uint sellerAmt = msg.value - commission;
            seller.transfer(sellerAmt);
            admin.transfer(commission);
            numOfTransfers++;
            return true;
        }
        else revert();
    }

     
     
     
     
     
 
    function recover(bytes32 offer, uint8 v, bytes32 r, bytes32 s) public view
        returns (address seller, uint16 quantity, uint256 price, bool agreementIsValid) {
        quantity = uint16(offer & 0xffff);
        price = uint256(offer >> 16 << 16);
        seller = ecrecover(offer, v, r, s);
        agreementIsValid = balances[seller] >= quantity;
    }

    function totalSupply() public constant returns(uint)
    {
        return totalTickets;
    }

    function eventName() public constant returns(string)
    {
        return name;
    }

    function eventVenue() public constant returns(string)
    {
        return venue;
    }

    function eventDate() public constant returns(string)
    {
        return date;
    }

    function getAmountTransferred() public view returns (uint)
    {
        return numOfTransfers;
    }

    function isContractExpired() public view returns (bool)
    {
        if(block.timestamp > expiryTimeStamp)
        {
            return true;
        }
        else return false;
    }

    function balanceOf(address _owner) public constant returns (uint)
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint _value) public returns(bool)
    {
        if(balances[msg.sender] < _value) revert();
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        numOfTransfers++;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value)
        adminOnly public returns (bool)
    {
        if(balances[_from] >= _value)
        {
            balances[_from] -= _value;
            balances[_to] += _value;
            TransferFrom(_from,_to, _value);
            numOfTransfers++;
            return true;
        }
        else return false;
    }
}