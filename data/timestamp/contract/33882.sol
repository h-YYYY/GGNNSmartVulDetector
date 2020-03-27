pragma solidity 0.4.18;
 


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a * b; assert(a == 0 || c / a == b); return c;}
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
    function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}
}

 
contract ReentryProtected {
     
     
    bool __reMutex;

     
     
     
     
     
     
    modifier preventReentry() {
        require(!__reMutex);
        __reMutex = true;
        _;
        delete __reMutex;
        return;
    }
     
}

 
contract MasteriumToken is ReentryProtected  {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8  public decimals;
    string public version;

     
    uint256 internal constant TOKEN_MULTIPLIER = 1e18;

    address internal contractOwner;

     
    bool    internal debug = false;

     
    uint256 internal constant DEBUG_SALEFACTOR = 1;  
    uint256 internal constant DEBUG_STARTDELAY = 1 minutes;
    uint256 internal constant DEBUG_INTERVAL   = 1 days;

     
    uint256 internal constant PRODUCTION_SALEFACTOR = 1;            
    uint256 internal constant PRODUCTION_START      = 1511611200;   
    uint256 internal constant PRODUCTION_INTERVAL   = 30 days;

    event DebugValue(string text, uint256 value);



    struct Account {
        uint256 balance;                         
        uint256 lastPayoutInterval;              
    }

    mapping(address => Account)                      internal accounts;
    mapping(address => mapping(address => uint256))  public allowed;


    uint256 internal _supplyTotal;
    uint256 internal _supplyLastPayoutInterval;  


     
     
     
     
     
     
     
     
    struct InterestConfig {
        uint256 interval;            
        uint256 periodicity;         
        uint256 stopAtInterval;      
        uint256 startAtTimestamp;    
    }

    InterestConfig internal interestConfig;  

    uint256[12] internal interestRates;
    uint256[4]  internal stageFactors;



     
     
     
     
     
     
     
     
     
    struct StructMasternode {
        uint8   activeMasternodes;               
        uint256 totalBalanceWei;                 
        uint256 rewardPool;                      
        uint256 rewardsPayedTotal;               

        uint256 miningRewardInTokens;            
        uint256 totalTokensMinedRaw1e18;         

        uint256 transactionRewardInSubtokensRaw1e18; 

        uint256 minBalanceRequiredInTokens;      
        uint256 minBalanceRequiredInSubtokensRaw1e18; 

        uint256 minDepositRequiredInEther;       
        uint256 minDepositRequiredInWei;         
        uint8   maxMasternodesAllowed;           
    }

    struct Masternode {
        address addr;            
        uint256 balanceWei;      
        uint256 sinceInterval;                   
        uint256 lastMiningInterval;              
    }

    StructMasternode public masternode;  
    Masternode[22]   public masternodes;
    uint8 internal constant maxMasternodes = 22;
    uint256 internal miningRewardInSubtokensRaw1e18;  


     
     
     
     
     
     
     
     
     

    struct Structtokensale {  
         
        uint256 initialTokenSupplyRAW1e18;       
        uint256 initialTokenSupplyAmount;
        uint256 initialTokenSupplyFraction;

        uint256 minPaymentRequiredUnitWei;       
        uint256 maxPaymentAllowedUnitWei;        

        uint256 startAtTimestamp;                

        bool    tokenSaleClosed;                 
        bool    tokenSalePaused;                 

        uint256 totalWeiRaised;                  
        uint256 totalWeiInFallback;        

        uint256 totalTokensDistributedRAW1e18;
        uint256 totalTokensDistributedAmount;
        uint256 totalTokensDistributedFraction;
    }

    Structtokensale public tokensale;
    address adminWallet;         
    bool    sendFundsToWallet;   
    uint256 internal contractCreationTimestamp;       
    uint256[20] tokensaleFactor;

     



     
     
     
     
     
    function MasteriumToken() payable public {  
         
        name     = (debug) ? "Masterium_Testnet" : "Masterium";
        symbol   = (debug) ? "MTITestnet" : "MTI";
        version  = (debug) ? "1.00.00.Testnet" : "1.00.00";
        decimals = 18;  

        contractOwner = msg.sender;

        adminWallet = 0xAb942256b49F0c841D371DC3dFe78beFea447a27;

        sendFundsToWallet = true;

        contractCreationTimestamp = _getTimestamp();

         
        tokensale.initialTokenSupplyRAW1e18 = 20000000 * TOKEN_MULTIPLIER;  
        tokensale.initialTokenSupplyAmount  = tokensale.initialTokenSupplyRAW1e18 / TOKEN_MULTIPLIER;
        tokensale.initialTokenSupplyFraction= tokensale.initialTokenSupplyRAW1e18 % TOKEN_MULTIPLIER;

         
        tokensale.minPaymentRequiredUnitWei = 0.0001 ether;  
        tokensale.maxPaymentAllowedUnitWei  = 100 ether;     

        require(adminWallet != address(0));
        require(tokensale.initialTokenSupplyRAW1e18 > 0);
        require(tokensale.minPaymentRequiredUnitWei > 0);
        require(tokensale.maxPaymentAllowedUnitWei > tokensale.minPaymentRequiredUnitWei);

        tokensale.tokenSalePaused = false;
        tokensale.tokenSaleClosed = false;

        tokensale.totalWeiRaised = 0;                
        tokensale.totalWeiInFallback = 0;      

        tokensale.totalTokensDistributedRAW1e18 = 0;
        tokensale.totalTokensDistributedAmount  = 0;
        tokensale.totalTokensDistributedFraction= 0;

        tokensale.startAtTimestamp = (debug) ? contractCreationTimestamp + _addTime(DEBUG_STARTDELAY) : PRODUCTION_START; 

        tokensaleFactor[0] = 2000;
        tokensaleFactor[1] = 1000;
        tokensaleFactor[2] = 800;
        tokensaleFactor[3] = 500;
        tokensaleFactor[4] = 500;
        tokensaleFactor[5] = 500;
        tokensaleFactor[6] = 500;
        tokensaleFactor[7] = 500;
        tokensaleFactor[8] = 500;
        tokensaleFactor[9] = 400;
        tokensaleFactor[10] = 400;
        tokensaleFactor[11] = 400;
        tokensaleFactor[12] = 200;
        tokensaleFactor[13] = 200;
        tokensaleFactor[14] = 200;
        tokensaleFactor[15] = 400;
        tokensaleFactor[16] = 500;
        tokensaleFactor[17] = 800;
        tokensaleFactor[18] = 1000;
        tokensaleFactor[19] = 2500;

        _supplyTotal = tokensale.initialTokenSupplyRAW1e18;
        _supplyLastPayoutInterval = 0;                                 

        accounts[contractOwner].balance = tokensale.initialTokenSupplyRAW1e18;
        accounts[contractOwner].lastPayoutInterval = 0;
         

         
        masternode.transactionRewardInSubtokensRaw1e18 = 0.01 * (1 ether);  

        masternode.miningRewardInTokens = 50000;  
        miningRewardInSubtokensRaw1e18 = masternode.miningRewardInTokens * TOKEN_MULTIPLIER;  

        masternode.totalTokensMinedRaw1e18 = 0;  

        masternode.minBalanceRequiredInTokens = 100000;  
        masternode.minBalanceRequiredInSubtokensRaw1e18 = masternode.minBalanceRequiredInTokens * TOKEN_MULTIPLIER;  

        masternode.maxMasternodesAllowed = uint8(maxMasternodes);
        masternode.activeMasternodes= 0;
        masternode.totalBalanceWei  = 0;
        masternode.rewardPool       = 0;
        masternode.rewardsPayedTotal= 0;

        masternode.minDepositRequiredInEther= requiredBalanceForMasternodeInEther(); 
        masternode.minDepositRequiredInWei  = requiredBalanceForMasternodeInWei();  


         
        interestConfig.interval = _addTime( (debug) ? DEBUG_INTERVAL : PRODUCTION_INTERVAL );  
        interestConfig.periodicity      = 12;     
        interestConfig.stopAtInterval   = 4 * interestConfig.periodicity;   
        interestConfig.startAtTimestamp = tokensale.startAtTimestamp;  

         
        interestRates[ 0] = 1000000000000;  
        interestRates[ 1] =  800000000000;  
        interestRates[ 2] =  600000000000;
        interestRates[ 3] =  400000000000;
        interestRates[ 4] =  200000000000;
        interestRates[ 5] =  100000000000;
        interestRates[ 6] =   50000000000;
        interestRates[ 7] =   50000000000;
        interestRates[ 8] =   30000000000;
        interestRates[ 9] =   40000000000;
        interestRates[10] =   20000000000;
        interestRates[11] =   10000000000;  

         
        stageFactors[0] =  1000000000000;  
        stageFactors[1] =  4000000000000;  
        stageFactors[2] =  8000000000000;
        stageFactors[3] = 16000000000000;
    }




     
     
     
     
     

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
     

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        _setBalances(msg.sender, _to, _value);  
        _sendFeesToMasternodes(masternode.transactionRewardInSubtokensRaw1e18);

        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);  
        _setBalances(_from, _to, _value);   
        _sendFeesToMasternodes(masternode.transactionRewardInSubtokensRaw1e18);

        Transfer(_from, _to, _value);
        return true;
    }

     
    function totalSupply() public constant returns (uint256  ) {
        return _calcBalance(_supplyTotal, _supplyLastPayoutInterval, intervalNow());
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return _calcBalance(accounts[_owner].balance, accounts[_owner].lastPayoutInterval, intervalNow());
    }

     
    function totalSupplyPretty() public constant returns (uint256 tokens, uint256 fraction) {
        uint256 _raw = totalSupply();
        tokens  = _raw / TOKEN_MULTIPLIER;
        fraction= _raw % TOKEN_MULTIPLIER;
    }

     
    function balanceOfPretty(address _owner) public constant returns (uint256 tokens, uint256 fraction) {
        uint256 _raw = balanceOf(_owner);
        tokens  = _raw / TOKEN_MULTIPLIER;
        fraction= _raw % TOKEN_MULTIPLIER;
    }


     
     
     
     
     
     
     

     
     
     
    function stageNow() public constant returns (uint256) {
        return intervalNow() / interestConfig.periodicity;
    }

     
     
    function intervalNow() public constant returns (uint256) {
        uint256 timestamp = _getTimestamp();
        return (timestamp < interestConfig.startAtTimestamp) ? 0 : (timestamp - interestConfig.startAtTimestamp) / interestConfig.interval;
    }

     
     
    function secToNextInterestPayout() public constant returns (uint256) {
        if (intervalNow() > interestConfig.stopAtInterval) return 0;  
         
         
         
         
         
        return (interestConfig.startAtTimestamp + (intervalNow() + 1) * interestConfig.interval) - _getTimestamp();
    }

     
     
    function interestNextInPercent() public constant returns (uint256 mainUnit, uint256 fraction) {
        uint256 _now = intervalNow();
        uint256 _raw = _calcBalance(100 * TOKEN_MULTIPLIER, _now, _now+1);
        mainUnit = (_raw - 100 * TOKEN_MULTIPLIER) / TOKEN_MULTIPLIER;
        fraction = (_raw - 100 * TOKEN_MULTIPLIER) % TOKEN_MULTIPLIER;
        return;
    }

     
     
    function _requestInterestPayoutToTotalSupply() internal {
         
        uint256 oldbal = _supplyTotal;    
        uint256 newbal = totalSupply();                                  
        if (oldbal < newbal) {   
            _supplyTotal = newbal;
        }
         
        _supplyLastPayoutInterval = intervalNow();  
    }

     
     
    function _requestInterestPayoutToAccountBalance(address _owner) internal {
         
        uint256 oldbal = accounts[_owner].balance;   
        uint256 newbal = balanceOf(_owner);          
        if (oldbal < newbal) {   
            accounts[_owner].balance = newbal;

             
        }
         
        accounts[_owner].lastPayoutInterval = intervalNow();  
    }

     
     
    function _setBalances(address _from, address _to, uint256 _value) internal {
        require(_from != _to);
        require(_value > 0);

         
        _requestInterestPayoutToAccountBalance(_from);    
         
         

         
        require(_value.add(masternode.transactionRewardInSubtokensRaw1e18) <= accounts[_from].balance);

         
        if (masternodeIsValid(_from)) {
            require(accounts[_from].balance >= masternode.minBalanceRequiredInSubtokensRaw1e18.add(_value));  
        }

         
        accounts[_from].balance = accounts[_from].balance.sub(_value).sub(masternode.transactionRewardInSubtokensRaw1e18);
        accounts[_to].balance   = accounts[_to].balance.add(_value);
    }

     
    function _calcBalance(uint256 _balance, uint256 _from, uint256 _to) internal constant returns (uint256) {
         
        uint256 _newbalance = _balance;
        if (_to > interestConfig.stopAtInterval) _to = interestConfig.stopAtInterval;  
        if (_from < _to) {  
            for (uint256 idx = _from; idx < _to; idx++) {  
                if (idx > 48) break;  

                _newbalance += (_newbalance * interestRates[idx % interestConfig.periodicity]) / stageFactors[(idx / interestConfig.periodicity) % 4];
            }
            if (_newbalance < _balance) { _newbalance = _balance; }  
        }
        return _newbalance;
         
    }






     
     
     
     
     
     
     
     
    event MasternodeRegistered(address indexed addr, uint256 amount);
    event MasternodeDeregistered(address indexed addr, uint256 amount);
    event MasternodeMinedTokens(address indexed addr, uint256 amount);
    event MasternodeTransferred(address fromAddr, address toAddr);
    event MasternodeRewardSend(uint256 amount);
    event MasternodeRewardAddedToRewardPool(uint256 amount);
    event MaxMasternodesAllowedChanged(uint8 newNumMaxMasternodesAllowed);
    event TransactionFeeChanged(uint256 newTransactionFee);
    event MinerRewardChanged(uint256 newMinerReward);

     
     
    function secToNextMiningInterval() public constant returns (uint256) {
        return secToNextInterestPayout();
    }

     
     
    function requiredBalanceForMasternodeInEther() constant internal returns (uint256) {
         
         
         
         
         
         
         
        return (masternode.activeMasternodes + 1) ** 2;
    }

     
    function requiredBalanceForMasternodeInWei() constant internal returns (uint256) {
        return (1 ether) * (masternode.activeMasternodes + 1) ** 2;
    }

     
    function masternodeRegister() payable public {
         
        require(msg.sender != address(0));
        require(masternode.activeMasternodes < masternode.maxMasternodesAllowed);        
        require(msg.value == requiredBalanceForMasternodeInWei() );                      
        require(_getMasternodeSlot(msg.sender) >= maxMasternodes);                       

        _requestInterestPayoutToTotalSupply();
        _requestInterestPayoutToAccountBalance(msg.sender);  
        require(accounts[msg.sender].balance >= masternode.minBalanceRequiredInSubtokensRaw1e18);  
         

        uint8 slot = _findEmptyMasternodeSlot();
        require(slot < maxMasternodes);  

        masternodes[slot].addr = msg.sender;
        masternodes[slot].balanceWei = msg.value;
        masternodes[slot].sinceInterval = intervalNow();
        masternodes[slot].lastMiningInterval = intervalNow();

        masternode.activeMasternodes++;

        masternode.minDepositRequiredInEther= requiredBalanceForMasternodeInEther();  
        masternode.minDepositRequiredInWei  = requiredBalanceForMasternodeInWei();  

        masternode.totalBalanceWei = masternode.totalBalanceWei.add(msg.value);     

        MasternodeRegistered(msg.sender, msg.value);
    }

     
    function masternodeDeregister() public preventReentry returns (bool _success) {
        require(msg.sender != address(0));
        require(masternode.activeMasternodes > 0);
        require(masternode.totalBalanceWei > 0);
        require(this.balance >= masternode.totalBalanceWei + tokensale.totalWeiInFallback);

        uint8 slot = _getMasternodeSlot(msg.sender);
        require(slot < maxMasternodes);  

        uint256 balanceWei = masternodes[slot].balanceWei;
        require(masternode.totalBalanceWei >= balanceWei);

        _requestInterestPayoutToTotalSupply();
        _requestInterestPayoutToAccountBalance(msg.sender);  

        masternodes[slot].addr = address(0);
        masternodes[slot].balanceWei = 0;
        masternodes[slot].sinceInterval = 0;
        masternodes[slot].lastMiningInterval = 0;

        masternode.totalBalanceWei = masternode.totalBalanceWei.sub(balanceWei);

        masternode.activeMasternodes--;

        masternode.minDepositRequiredInEther = requiredBalanceForMasternodeInEther();  
        masternode.minDepositRequiredInWei   = requiredBalanceForMasternodeInWei();  

         
        msg.sender.transfer(balanceWei);  

        MasternodeDeregistered(msg.sender, balanceWei);
        _success = true;
        }

     
    function masternodeMineTokens() public {
         
        require(msg.sender != address(0));
        require(masternode.activeMasternodes > 0);

        uint256 _inow = intervalNow();
        require(_inow <= interestConfig.stopAtInterval);  

        uint8 slot = _getMasternodeSlot(msg.sender);
        require(slot < maxMasternodes);  
        require(masternodes[slot].lastMiningInterval < _inow);  

        _requestInterestPayoutToTotalSupply();
        _requestInterestPayoutToAccountBalance(msg.sender);    
        require(accounts[msg.sender].balance >= masternode.minBalanceRequiredInSubtokensRaw1e18);  
         

        masternodes[slot].lastMiningInterval = _inow;

        uint256 _minedTokens = miningRewardInSubtokensRaw1e18;

         
        accounts[msg.sender].balance = accounts[msg.sender].balance.add(_minedTokens);

         
        _supplyTotal = _supplyTotal.add(_minedTokens);
         

        masternode.totalTokensMinedRaw1e18 = masternode.totalTokensMinedRaw1e18.add(_minedTokens);

        MasternodeMinedTokens(msg.sender, _minedTokens);
    }

     
    function masternodeTransferOwnership(address newAddr) public {
        require(masternode.activeMasternodes > 0);
        require(msg.sender != address(0));
        require(newAddr != address(0));
        require(newAddr != msg.sender);

        uint8 slot = _getMasternodeSlot(msg.sender);
        require(slot < maxMasternodes);  

        _requestInterestPayoutToTotalSupply();
        _requestInterestPayoutToAccountBalance(msg.sender);  
        require(accounts[newAddr].balance >= masternode.minBalanceRequiredInSubtokensRaw1e18);  
         

        masternodes[slot].addr = newAddr;

        MasternodeTransferred(msg.sender, newAddr);
    }

     
    function masternodeIsValid(address addr) public constant returns (bool) {
        return (_getMasternodeSlot(addr) < maxMasternodes) && (balanceOf(addr) >= masternode.minBalanceRequiredInSubtokensRaw1e18);
    }

     
    function _getMasternodeSlot(address addr) internal constant returns (uint8) {
        uint8 idx = maxMasternodes;  
        for (uint8 i = 0; i < maxMasternodes; i++) {
            if (masternodes[i].addr == addr) {  
                idx = i;
                break;
            }
        }
        return idx;  
    }

     
    function _findEmptyMasternodeSlot() internal constant returns (uint8) {
        uint8 idx = maxMasternodes;  

        if (masternode.activeMasternodes < maxMasternodes)
        for (uint8 i = 0; i < maxMasternodes; i++) {
            if (masternodes[i].addr == address(0) && masternodes[i].sinceInterval == 0) {  
                idx = i;
                break;
            }
        }
        return idx;  
    }

     
    function _sendFeesToMasternodes(uint256 _fee) internal {
        uint256 _pool = masternode.rewardPool;
        if (_fee + _pool > 0 && masternode.activeMasternodes > 0) {  
            masternode.rewardPool = 0;
            uint256 part = (_fee + _pool) / masternode.activeMasternodes;
            uint256 sum = 0;
            address addr;
            for (uint8 i = 0; i < maxMasternodes; i++) {
                addr = masternodes[i].addr;
                if (addr != address(0)) {
                    accounts[addr].balance = (accounts[addr].balance).add(part);  
                    sum += part;
                }
            }
            if (sum < part) masternode.rewardPool = part - sum;  
            masternode.rewardsPayedTotal += sum;
            MasternodeRewardSend(sum);
        } else {  
            masternode.rewardPool = masternode.rewardPool.add(_fee);
            MasternodeRewardAddedToRewardPool(_fee);
        }
    }



     
     
     
     
     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenSaleFinished();
    event TokenSaleClosed();
    event TokenSaleOpened();
    event TokenSalePaused(bool paused);

     
     
    function () payable public {
         
        _buyTokens(msg.sender, true);  
    }
     
    
     
    function tokensaleBuyTokens() payable public {
        _buyTokens(msg.sender, false);  
    }

     
    function tokensaleStageNow() public constant returns (uint256) {
        return tokensaleStageAt(tokensale.totalTokensDistributedRAW1e18);
    }

     
    function tokensaleStageAt(uint256 _tokensdistibutedRAW1e18) public pure returns (uint256) {
        return _tokensdistibutedRAW1e18 / (1000000 * TOKEN_MULTIPLIER);
    }

     
    function tokensaleTokensPerEtherNow() public constant returns (uint256) {
        return _tokensaleTokensPerEther(tokensale.totalTokensDistributedRAW1e18);
    }

     
     

     
    function _tokensaleTokensPerEther(uint256 _tokensdistibuted) internal constant returns (uint256) {
        uint256 factor = tokensaleFactor[tokensaleStageAt(_tokensdistibuted) % 20];  
        return factor * ( (debug) ? DEBUG_SALEFACTOR : PRODUCTION_SALEFACTOR );  

         
         
         
    }

     
    function _buyTokens(address addr, bool failsafe) internal {
        require(addr != address(0));
        require(msg.value > 0);
        require(msg.value >= tokensale.minPaymentRequiredUnitWei);  
        require(msg.value <= tokensale.maxPaymentAllowedUnitWei);  
        require(tokensaleStarted() && !tokensaleFinished() && !tokensalePaused());

        uint256 amountTokens;
        uint256 actExchangeRate = _tokensaleTokensPerEther(tokensale.totalTokensDistributedRAW1e18);
        uint256 amountTokensToBuyAtThisRate = msg.value * actExchangeRate;
        uint256 availableAtThisRate = (1000000 * TOKEN_MULTIPLIER) - ((tokensale.totalTokensDistributedRAW1e18) % (1000000 * TOKEN_MULTIPLIER));

        if (amountTokensToBuyAtThisRate <= availableAtThisRate) {  
            amountTokens = amountTokensToBuyAtThisRate;
        } else {  
            amountTokens = availableAtThisRate;
             
             

            amountTokens += (msg.value - availableAtThisRate / actExchangeRate) * _tokensaleTokensPerEther(tokensale.totalTokensDistributedRAW1e18 + amountTokens);  
        }

        require(amountTokens > 0);
        require(tokensale.totalTokensDistributedRAW1e18.add(amountTokens) <= tokensale.initialTokenSupplyRAW1e18);  

        _requestInterestPayoutToTotalSupply();
        _requestInterestPayoutToAccountBalance(contractOwner);  
        _requestInterestPayoutToAccountBalance(addr);  

        tokensale.totalWeiRaised = tokensale.totalWeiRaised.add(msg.value);
        if (!sendFundsToWallet || failsafe) tokensale.totalWeiInFallback = tokensale.totalWeiInFallback.add(msg.value);

        tokensale.totalTokensDistributedRAW1e18 = tokensale.totalTokensDistributedRAW1e18.add(amountTokens);
        tokensale.totalTokensDistributedAmount = tokensale.totalTokensDistributedRAW1e18 / TOKEN_MULTIPLIER;
        tokensale.totalTokensDistributedFraction = tokensale.totalTokensDistributedRAW1e18 % TOKEN_MULTIPLIER;

         
        accounts[contractOwner].balance = accounts[contractOwner].balance.sub(amountTokens);
        accounts[addr].balance = accounts[addr].balance.add(amountTokens);


         
        if (debug) {
             
            Contributor memory newcont;
            newcont.addr = addr;
            newcont.amountWei = msg.value;
            newcont.amountTokensUnit1e18 = amountTokens;
            newcont.sinceInterval = intervalNow();
            tokensaleContributors.push( newcont );
        }
         

         
        if (sendFundsToWallet && !failsafe) adminWallet.transfer(msg.value);  

        TokensPurchased(contractOwner, addr, msg.value, amountTokens);
    }

     
    function tokensaleSecondsToStart() public constant returns (uint256) {
         
        return (tokensale.startAtTimestamp <= _getTimestamp()) ? 0 : tokensale.startAtTimestamp - _getTimestamp();
    }


     
    function tokensaleStarted() internal constant returns (bool) {
        return _getTimestamp() >= tokensale.startAtTimestamp;
    }

     
    function tokensaleFinished() internal constant returns (bool) {
        return (tokensale.totalTokensDistributedRAW1e18 >= tokensale.initialTokenSupplyRAW1e18 || tokensale.tokenSaleClosed);
    }

     
    function tokensalePaused() internal constant returns (bool) {
        return tokensale.tokenSalePaused;
    }


     
     
     
     
     
    event AdminTransferredOwnership(address indexed previousOwner, address indexed newOwner);
    event AdminChangedFundingWallet(address oldAddr, address newAddr);

     
    function adminCommand(uint8 command, address addr, uint256 fee) onlyOwner public returns (bool) {
        require(command >= 0 && command <= 255);
        if (command == 1) {  
             
             
             
             

            require(this.balance >= tokensale.totalWeiInFallback);

            uint256 _withdrawBalance = this.balance.sub(masternode.totalBalanceWei);
            require(_withdrawBalance > 0);

            adminWallet.transfer(_withdrawBalance);
            tokensale.totalWeiInFallback = 0;
            return true;
        } else

        if (command == 15) {  
             
            _requestInterestPayoutToTotalSupply();
            _requestInterestPayoutToAccountBalance(contractOwner);  
        } else

        if (command == 22) {  
            require(fee >= 0 && fee <= (9999 * TOKEN_MULTIPLIER) && fee != masternode.transactionRewardInSubtokensRaw1e18);
            masternode.transactionRewardInSubtokensRaw1e18 = fee;

            TransactionFeeChanged(fee);
            return true;
        } else
        if (command == 33) {  
            require(fee >= 0 && fee <= (999999) && fee != masternode.miningRewardInTokens);

            masternode.miningRewardInTokens = fee;                               
            miningRewardInSubtokensRaw1e18 = fee * TOKEN_MULTIPLIER;  

            MinerRewardChanged(fee);
            return true;
        } else

        if (command == 111) {  
            tokensale.tokenSaleClosed = true;

            TokenSaleClosed();
            return true;
        } else
        if (command == 112) {  
            tokensale.tokenSaleClosed = false;

            TokenSaleOpened();
            return true;
        } else
        if (command == 113) {  
            tokensale.tokenSalePaused = true;

            TokenSalePaused(true);
            return true;
        } else
        if (command == 114) {  
            tokensale.tokenSalePaused = false;

            TokenSalePaused(false);
            return true;
        } else

        if (command == 150) {  
            require(addr != address(0));
            address oldOwner = contractOwner;
            contractOwner = addr;

            AdminTransferredOwnership(oldOwner, addr);
            return true;
        } else
        if (command == 152) {  
            require(addr != address(0));
            require(addr != adminWallet);
            address oldAddr = adminWallet;
            adminWallet = addr;

            AdminChangedFundingWallet(oldAddr, addr);
            return true;
        } else

        if (command == 225) {  
            require(debug || PRODUCTION_START>_getTimestamp());  

            DebugValue("debug: suicide", this.balance);
            selfdestruct(contractOwner);
            return true;
        }
         
        return false;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function _getTimestamp() internal constant returns (uint256) {
        return now;  
         
    }

    function _addTime(uint256 _sec) internal pure returns (uint256) {
        return _sec * (1 seconds);  
    }
}