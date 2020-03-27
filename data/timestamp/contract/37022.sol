pragma solidity ^0.4.11;


 
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}
 
 
contract Owned {

     
     
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount)
    returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

 
 
 
contract MiniMeToken is Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               
    string public version = 'MMT_0.1';  


     
     
     
    struct  Checkpoint {

     
    uint128 fromBlock;

     
    uint128 value;
    }

     
     
    MiniMeToken public parentToken;

     
     
    uint public parentSnapShotBlock;

     
    uint public creationBlock;

     
     
     
    mapping (address => Checkpoint[]) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    Checkpoint[] totalSupplyHistory;

     
    bool public transfersEnabled;

     
    MiniMeTokenFactory public tokenFactory;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
    function MiniMeToken(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                  
        decimals = _decimalUnits;                           
        symbol = _tokenSymbol;                              
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = getBlockNumber();
    }


     
     
     

     
     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

         
         
         
         
        if (msg.sender != controller) {
            if (!transfersEnabled) throw;

             
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

        if (_amount == 0) {
            return true;
        }

        if (parentSnapShotBlock >= getBlockNumber()) throw;

         
        if ((_to == 0) || (_to == address(this))) throw;

         
         
        var previousBalanceFrom = balanceOfAt(_from, getBlockNumber());
        if (previousBalanceFrom < _amount) {
            return false;
        }

         
        if (isContract(controller)) {
            if (!TokenController(controller).onTransfer(_from, _to, _amount))
            throw;
        }

         
         
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

         
         
        var previousBalanceTo = balanceOfAt(_to, getBlockNumber());
        if (previousBalanceTo + _amount < previousBalanceTo) throw;  
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);

         
        Transfer(_from, _to, _amount);

        return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, getBlockNumber());
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;

         
         
         
         
        if ((_amount!=0) && (allowed[msg.sender][_spender] !=0)) throw;

         
        if (isContract(controller)) {
            if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
            throw;
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
     
     
     
     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        if (!approve(_spender, _amount)) throw;

        ApproveAndCallFallBack(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
        );

        return true;
    }

     
     
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(getBlockNumber());
    }


     
     
     

     
     
     
     
    function balanceOfAt(address _owner, uint _blockNumber) constant
    returns (uint) {

         
         
         
         
         
        if ((balances[_owner].length == 0)
        || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                 
                return 0;
            }

             
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

     
     
     
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

         
         
         
         
         
        if ((totalSupplyHistory.length == 0)
        || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

             
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
    string _cloneTokenName,
    uint8 _cloneDecimalUnits,
    string _cloneTokenSymbol,
    uint _snapshotBlock,
    bool _transfersEnabled
    ) returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = getBlockNumber();
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
        this,
        _snapshotBlock,
        _cloneTokenName,
        _cloneDecimalUnits,
        _cloneTokenSymbol,
        _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

         
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

     
     
     

     
     
     
     
    function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
        if (curTotalSupply + _amount < curTotalSupply) throw;  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        var previousBalanceTo = balanceOf(_owner);
        if (previousBalanceTo + _amount < previousBalanceTo) throw;  
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


     
     
     
     
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
        if (curTotalSupply < _amount) throw;
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        var previousBalanceFrom = balanceOf(_owner);
        if (previousBalanceFrom < _amount) throw;
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

     
     
     


     
     
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }

     
     
     

     
     
     
     
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

         
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
        return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

         
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

     
     
     
     
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < getBlockNumber())) {
            Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
            newCheckPoint.fromBlock =  uint128(getBlockNumber());
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
        size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

     
     
     
    function ()  payable {
        if (isContract(controller)) {
            if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender))
            throw;
        } else {
            throw;
        }
    }


     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

     
     
     

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _amount
    );

}


 
 
 

 
 
 
contract MiniMeTokenFactory {

     
     
     
     
     
     
     
     
     
     
    function createCloneToken(
    address _parentToken,
    uint _snapshotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
        this,
        _parentToken,
        _snapshotBlock,
        _tokenName,
        _decimalUnits,
        _tokenSymbol,
        _transfersEnabled
        );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

contract FCCContribution is Owned, TokenController {

    using SafeMath for uint256;
    MiniMeToken public FCC;

    uint256 public constant MIN_FUND = (0.001 ether);
    uint256 public constant CRAWDSALE_END_DAY = 2;

    uint256 public dayCycle = 10 days;
    uint256 public startTimeEarlyBird=0 ;
    uint256 public startTime=0 ;
    uint256 public endTime =0;
    uint256 public finalizedBlock=0;
    uint256 public finalizedTime=0;

    bool public isFinalize = false;
    bool public isPause = false;

    uint256 public totalContributedETH = 0;
    uint256 public totalTokenSaled=0;

    uint256 public MaxEth=5000 ether;

    uint256[] public ratio;

    address public fccController;
    address public destEthFoundationDev;
    address public destEthFoundation;
    uint256 public proportion;

    bool public paused;

    modifier initialized() {
        require(address(FCC) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTimeEarlyBird &&
        time() <= endTime &&
        finalizedBlock == 0 &&
        address(FCC) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function FCCContribution() {
        paused = false;
        ratio.push(19500);
        ratio.push(18500);
        ratio.push(17500);
    }


     
     
     
     
     
     
     
     
     
     
    function initialize(
    address _fcc,
    address _fccController,
    uint256 _startTimeEarlyBird,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _dayCycle,
    address _destEthFoundationDev,
    address _destEthFoundation,
    uint256 _proportion     
    ) public onlyOwner {
         
        require(address(FCC) == 0x0);

        FCC = MiniMeToken(_fcc);
        require(FCC.totalSupply() == 0);
        require(FCC.controller() == address(this));
        require(FCC.decimals() == 18);   

        startTime = _startTime;
        startTimeEarlyBird=_startTimeEarlyBird;
        endTime = _endTime;
        dayCycle=_dayCycle;

        assert(startTime < endTime);

        require(_fccController != 0x0);
        fccController = _fccController;

        require(_destEthFoundationDev != 0x0);
        destEthFoundationDev = _destEthFoundationDev;

        require(_destEthFoundation != 0x0);
        destEthFoundation = _destEthFoundation;

        proportion=_proportion;

    }

    function changeRatio(uint256 _day,uint256 _ratio)onlyOwner{
        ratio[_day]=_ratio;
    }

     
     
    function () public payable notPaused {
        if(totalContributedETH>=MaxEth) throw;
        proxyPayment(msg.sender);
    }


     
     
     

     
     
     
     
    function proxyPayment(address _account) public payable initialized contributionOpen returns (bool) {
        require(_account != 0x0);
        uint256 day = today();

        require( msg.value >= MIN_FUND );

        uint256 toDev;
        if(proportion<100){
            toDev=msg.value*100/proportion;
            destEthFoundationDev.transfer(toDev);
            destEthFoundation.transfer(msg.value-toDev);
        }else
        {
            destEthFoundationDev.transfer(msg.value);
        }

        uint256 r=ratio[day];
        require(r>0);

        uint256 tokenSaling=r.mul(msg.value);
        assert(FCC.generateTokens(_account,tokenSaling));

        totalContributedETH += msg.value;
        totalTokenSaled+=tokenSaling;

        NewSale(day, msg.sender, msg.value);
    }
    function onTransfer(address, address, uint256) public returns (bool) {
        return false;
    }

    function onApprove(address, address, uint256) public returns (bool) {
        return false;
    }
    function issueTokenToAddress(address _account, uint256 _amount,uint256 _ethAmount) onlyOwner initialized {


        assert(FCC.generateTokens(_account, _amount));

        totalContributedETH +=_amount;

        NewIssue(_account, _amount, _ethAmount);

    }

    function finalize() public onlyOwner initialized {
        require(time() >= startTime);

        require(finalizedBlock == 0);

        finalizedTime = getBlockNumber();
        finalizedTime = now;

        FCC.changeController(fccController);
        Finalized();
    }

     
     
     
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) return false;
        uint256 size;
        assembly {
        size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function time() constant returns (uint) {
        return block.timestamp;
    }

     
     
     

     
    function tokensIssued() public constant returns (uint256) {
        return FCC.totalSupply();
    }

     
     
     

     
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (FCC.controller() == address(this)) {
            FCC.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

     
    function pauseContribution() onlyOwner {
        paused = true;
    }

     
    function resumeContribution() onlyOwner {
        paused = false;
    }

    function today() constant returns (uint) {
        if(now<startTime)
        return 0;
        return now.sub( startTime) / dayCycle + 1;
    }
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(uint256 _day ,address _account, uint256 _amount);
    event NewIssue(address indexed _th, uint256 _amount, uint256  _ethAmount);
    event Finalized();
}
contract FCCPlaceHolder is TokenController, Owned {
    using SafeMath for uint256;

    MiniMeToken public fcc;
    FCCContribution public contribution;
    uint256 public activationTime;

    mapping(address => bool) public whitelist;

     
     
     
     
    function FCCPlaceHolder(address _owner, address _fcc, address _contribution) {
        owner = _owner;
        fcc = MiniMeToken(_fcc);
        contribution = FCCContribution(_contribution);
    }

     
     
     
    function changeController(address _newController) public onlyOwner {
        fcc.changeController(_newController);
        ControllerChanged(_newController);
    }


     
     
     

     
    function proxyPayment(address) public payable returns (bool) {
        return false;
    }

    function onTransfer(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function onApprove(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function transferable(address _from) internal returns (bool) {
         
        if (activationTime == 0) {
            uint256 f = contribution.finalizedTime();
            if (f > 0) {
                activationTime = f.add(60);
            } else {
                return false;
            }
        }
        return (getTime() > activationTime) || (whitelist[_from] == true);
    }


     
     
     

     
    function getTime() internal returns (uint256) {
        return now;
    }


     
     
     

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (fcc.controller() == address(this)) {
            fcc.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event ControllerChanged(address indexed _newController);
}