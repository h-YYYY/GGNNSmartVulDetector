pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterShell {
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public director;
    bool public directorLock;
    uint256 public feeAmount;
    uint256 public retentionMin;
    uint256 public retentionMax;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public locked;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed _from, uint256 _value);
    
     
    event Lock(address indexed _target, uint256 _value, uint256 _interval);
    
     
    event Claim(address indexed _target, address indexed _payout, address indexed _fee);

     
    function OysterShell() public {
        director = msg.sender;
        name = "Oyster Shell TEST";
        symbol = "PRESHL";
        decimals = 18;
        directorLock = false;
        totalSupply = 98592692;
        
         
        balances[director] = totalSupply;
        
         
        feeAmount = 10;
        
         
        retentionMin = 20;
        
         
        retentionMax = 200;
    }
    
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    modifier onlyDirector {
         
         
        require(!directorLock);
        
         
        require(msg.sender == director);
        _;
    }
    
    modifier onlyDirectorForce {
         
        require(msg.sender == director);
        _;
    }
    
     
    function transferDirector(address newDirector) public onlyDirectorForce {
        director = newDirector;
    }
    
     
    function withdrawFunds() public onlyDirectorForce {
        director.transfer(this.balance);
    }
    
     
    function selfLock() public payable onlyDirector {
         
        require(msg.value == 10 ether);
        
         
        directorLock = true;
    }
    
     
    function amendFee(uint256 feeAmountSet) public onlyDirector returns (bool success) {
        feeAmount = feeAmountSet;
        return true;
    }
    
     
    function amendRetention(uint256 retentionMinSet, uint256 retentionMaxSet) public onlyDirector returns (bool success) {
         
        retentionMin = retentionMinSet;
        
         
        retentionMax = retentionMaxSet;
        return true;
    }
    
     
    function lock(uint256 interval) public returns (bool success) {
         
        require(locked[msg.sender] == 0);
        
         
        require(balances[msg.sender] >= retentionMin);
        
         
        require(balances[msg.sender] <= retentionMax);
        
         
        locked[msg.sender] = interval;
        
         
        Lock(msg.sender, balances[msg.sender], interval);
        return true;
    }
    
     
    function claim(address _payout, address _fee) public returns (bool success) {
         
        require(locked[msg.sender] >= block.timestamp);
        
         
        require(_payout != _fee);
        
         
        require(msg.sender != _payout);
        
         
        require(msg.sender != _fee);
        
         
        require(balances[msg.sender] >= retentionMin);
        
         
        uint256 previousBalances = balances[msg.sender] + balances[_payout] + balances[_fee];
        
         
        uint256 payAmount = balances[msg.sender] - feeAmount;
        
         
        balances[msg.sender] = 0;
        
         
        balances[_payout] += payAmount;
        
         
        balances[_fee] += feeAmount;
        
         
        Claim(msg.sender, _payout, _fee);
        Transfer(msg.sender, _payout, payAmount);
        Transfer(msg.sender, _fee, feeAmount);
        
         
        assert(balances[msg.sender] + balances[_payout] + balances[_fee] == previousBalances);
        return true;
    }
    
     
    function () public payable {
         
        require(false);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(locked[_from] == 0);
        
         
        if (locked[_to] > 0) {
            require(balances[_to] + _value <= retentionMax);
        }
        
         
        require(_to != 0x0);
        
         
        require(balances[_from] >= _value);
        
         
        require(balances[_to] + _value > balances[_to]);
        
         
        uint256 previousBalances = balances[_from] + balances[_to];
        
         
        balances[_from] -= _value;
        
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        require(locked[msg.sender] == 0);
        
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(locked[msg.sender] == 0);
        
         
        require(balances[msg.sender] >= _value);
        
         
        balances[msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(locked[_from] == 0);
        
         
        require(balances[_from] >= _value);
        
         
        require(_value <= allowance[_from][msg.sender]);
        
         
        balances[_from] -= _value;
        
         
        allowance[_from][msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}