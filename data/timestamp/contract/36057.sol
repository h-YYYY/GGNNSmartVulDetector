 
pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library Math {
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
 
 
library UintLib {
    using SafeMath  for uint;

    function tolerantSub(uint x, uint y) constant returns (uint z) {
        if (x >= y) z = x - y;
        else z = 0;
    }

    function next(uint i, uint size) internal constant returns (uint) {
        return (i + 1) % size;
    }

    function prev(uint i, uint size) internal constant returns (uint) {
        return (i + size - 1) % size;
    }

     
     
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        constant
        returns (uint) {

        uint len = arr.length;
        require(len > 1);
        require(scale > 0);

        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg += arr[i];
        }

        avg = avg.div(len);

        if (avg == 0) {
            return 0;
        }

        uint cvs = 0;
        for (i = 0; i < len; i++) {
            uint sub = 0;
            if (arr[i] > avg) {
                sub = arr[i] - avg;
            } else {
                sub = avg - arr[i];
            }
            cvs += sub.mul(sub);
        }
        return cvs
            .mul(scale)
            .div(avg)
            .mul(scale)
            .div(avg)
            .div(len - 1);
    }
}

 
 
 
library Uint8Lib {
    function xorReduce(
        uint8[] arr,
        uint    len
        )
        public
        constant
        returns (uint8 res) {

        res = arr[0];
        for (uint i = 1; i < len; i++) {
           res ^= arr[i];
        }
    }
}

 
 
library ErrorLib {

    event Error(string message);

     
    function orThrow(bool condition, string message) public constant {
        if (!condition) {
            error(message);
        }
    }

    function error(string message) public constant {
        Error(message);
        revert();
    }
}

 
 
 
library Bytes32Lib {

    function xorReduce(
        bytes32[]   arr,
        uint        len
        )
        public
        constant
        returns (bytes32 res) {

        res = arr[0];
        for (uint i = 1; i < len; i++) {
            res = _xor(res, arr[i]);
        }
    }

    function _xor(
        bytes32 bs1,
        bytes32 bs2
        )
        public
        constant
        returns (bytes32 res) {

        bytes memory temp = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            temp[i] = bs1[i] ^ bs2[i];
        }
        string memory str = string(temp);
        assembly {
            res := mload(add(str, 32))
        }
    }
}

 
 
 
contract TokenRegistry is Ownable {

    address[] public tokens;

    mapping (string => address) tokenSymbolMap;

    function registerToken(address _token, string _symbol)
        public
        onlyOwner {
        require(_token != address(0));
        require(!isTokenRegisteredBySymbol(_symbol));
        require(!isTokenRegistered(_token));
        tokens.push(_token);
        tokenSymbolMap[_symbol] = _token;
    }

    function unregisterToken(address _token, string _symbol)
        public
        onlyOwner {
        require(tokenSymbolMap[_symbol] == _token);
        delete tokenSymbolMap[_symbol];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] == tokens[tokens.length - 1];
                tokens.length --;
                break;
            }
        }
    }

    function isTokenRegisteredBySymbol(string symbol)
        public
        constant
        returns (bool) {
        return tokenSymbolMap[symbol] != address(0);
    }

    function isTokenRegistered(address _token)
        public
        constant
        returns (bool) {

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getAddressBySymbol(string symbol)
        public
        constant
        returns (address) {
        return tokenSymbolMap[symbol];
    }
}

 
 
 
 
contract TokenTransferDelegate is Ownable {
    using Math for uint;

     
     
     

    uint lastVersion = 0;
    address[] public versions;
    mapping (address => uint) public versioned;


     
     
     

    modifier isVersioned(address addr) {
        if (versioned[addr] == 0) {
            revert();
        }
        _;
    }

    modifier notVersioned(address addr) {
        if (versioned[addr] > 0) {
            revert();
        }
        _;
    }


     
     
     

    event VersionAdded(address indexed addr, uint version);

    event VersionRemoved(address indexed addr, uint version);


     
     
     

     
     
    function addVersion(address addr)
        onlyOwner
        notVersioned(addr)
        {
        versioned[addr] = ++lastVersion;
        versions.push(addr);
        VersionAdded(addr, lastVersion);
    }

     
     
    function removeVersion(address addr)
        onlyOwner
        isVersioned(addr)
        {
        uint version = versioned[addr];
        delete versioned[addr];

        uint length = versions.length;
        for (uint i = 0; i < length; i++) {
            if (versions[i] == addr) {
                versions[i] = versions[length - 1];
                versions.length -= 1;
                break;
            }
        }
        VersionRemoved(addr, version);
    }


     
     
     
    function getSpendable(
        address tokenAddress,
        address _owner
        )
        isVersioned(msg.sender)
        constant
        returns (uint) {

        var token = ERC20(tokenAddress);
        return token
            .allowance(_owner, address(this))
            .min256(token.balanceOf(_owner));
    }


     
     
     
     
     
     
    function transferToken(
        address token,
        address from,
        address to,
        uint value)
        isVersioned(msg.sender)
        returns (bool) {
        return ERC20(token).transferFrom(from, to, value);
    }

     
     
    function getVersions()
        constant
        returns (address[]) {
        return versions;
    }
}

contract RinghashRegistry {
    using Bytes32Lib    for bytes32[];
    using ErrorLib      for bool;
    using Uint8Lib      for uint8[];

    uint public blocksToLive;

    struct Submission {
        address feeRecepient;
        uint block;
    }

    mapping (bytes32 => Submission) submissions;

    function RinghashRegistry(uint _blocksToLive) public {
        require(_blocksToLive > 0);
        blocksToLive = _blocksToLive;
    }

    function submitRinghash(
        uint        ringSize,
        address     feeRecepient,
         
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList)
        public {
        bytes32 ringhash = calculateRinghash(
            ringSize,
             
             
            vList,
            rList,
            sList);

        canSubmit(ringhash, feeRecepient)
            .orThrow("Ringhash submitted");

        submissions[ringhash] = Submission(feeRecepient, block.number);
    }

    function canSubmit(
        bytes32 ringhash,
        address feeRecepient
        )
        public
        constant
        returns (bool) {

        var submission = submissions[ringhash];
        return (submission.feeRecepient == address(0)
            || submission.block + blocksToLive < block.number
            || submission.feeRecepient == feeRecepient);
    }

     
    function ringhashFound(bytes32 ringhash)
        public
        constant
        returns (bool) {

        return submissions[ringhash].feeRecepient != address(0);
    }

     
    function calculateRinghash(
        uint        ringSize,
         
         
        uint8[]     vList,
        bytes32[]   rList,
        bytes32[]   sList
        )
        public
        constant
        returns (bytes32) {

        (ringSize == vList.length - 1
            && ringSize == rList.length - 1
            && ringSize == sList.length - 1)
            .orThrow("invalid ring data");

        return keccak256(
             
             
            vList.xorReduce(ringSize),
            rList.xorReduce(ringSize),
            sList.xorReduce(ringSize));
    }
}

 
 
 
contract LoopringProtocol {

     
     
     
    uint    public constant FEE_SELECT_LRC               = 0;
    uint    public constant FEE_SELECT_MARGIN_SPLIT      = 1;
    uint    public constant FEE_SELECT_MAX_VALUE         = 1;

    uint    public constant MARGIN_SPLIT_PERCENTAGE_BASE = 10000;


     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct Order {
        address owner;
        address tokenS;
        address tokenB;
        uint    amountS;
        uint    amountB;
        uint    timestamp;
        uint    ttl;
        uint    salt;
        uint    lrcFee;
        bool    buyNoMoreThanAmountB;
        uint8   marginSplitPercentage;
        uint8   v;
        bytes32 r;
        bytes32 s;
    }


     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient,
        bool            throwIfLRCIsInsuffcient
        ) public;

     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        ) public;

     
     
     
     
     
    function setCutoff(uint cutoff) public;
}

 
 
 
contract LoopringProtocolImpl is LoopringProtocol {
    using ErrorLib  for bool;
    using Math      for uint;
    using SafeMath  for uint;
    using UintLib   for uint;

     
     
     

    address public  lrcTokenAddress             = address(0);
    address public  tokenRegistryAddress        = address(0);
    address public  ringhashRegistryAddress     = address(0);
    address public  delegateAddress             = address(0);

    uint    public  maxRingSize                 = 0;
    uint    public  ringIndex                   = 0;
    bool    private entered                     = false;

     
     
     
     
     
     
     
     
     
    uint    public  rateRatioCVSThreshold       = 0;

    uint    public constant RATE_RATIO_SCALE    = 10000;

     
     
    mapping (bytes32 => uint) public filled;
    mapping (bytes32 => uint) public cancelled;

     
    mapping (address => uint) public cutoffs;


     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct OrderState {
        Order   order;
        bytes32 orderHash;
        uint8   feeSelection;
        uint    rateAmountS;
        uint    availableAmountS;
        uint    fillAmountS;
        uint    lrcReward;
        uint    lrcFee;
        uint    splitS;
        uint    splitB;
    }

    struct Ring {
        bytes32      ringhash;
        OrderState[] orders;
        address      miner;
        address      feeRecepient;
        bool         throwIfLRCIsInsuffcient;
    }


     
     
     

    event RingMined(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        address     indexed _miner,
        address     indexed _feeRecepient,
        bool                _ringhashFound);

    event OrderFilled(
        uint                _ringIndex,
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _ringhash,
        bytes32             _prevOrderHash,
        bytes32     indexed _orderHash,
        bytes32              _nextOrderHash,
        uint                _amountS,
        uint                _amountB,
        uint                _lrcReward,
        uint                _lrcFee);

    event OrderCancelled(
        uint                _time,
        uint                _blocknumber,
        bytes32     indexed _orderHash,
        uint                _amountCancelled);

    event CutoffTimestampChanged(
        uint                _time,
        uint                _blocknumber,
        address     indexed _address,
        uint                _cutoff);


     
     
     

    function LoopringProtocolImpl(
        address _lrcTokenAddress,
        address _tokenRegistryAddress,
        address _ringhashRegistryAddress,
        address _delegateAddress,
        uint    _maxRingSize,
        uint    _rateRatioCVSThreshold
        )
        public {

        require(address(0) != _lrcTokenAddress);
        require(address(0) != _tokenRegistryAddress);
        require(address(0) != _delegateAddress);

        require(_maxRingSize > 1);
        require(_rateRatioCVSThreshold > 0);

        lrcTokenAddress             = _lrcTokenAddress;
        tokenRegistryAddress        = _tokenRegistryAddress;
        ringhashRegistryAddress     = _ringhashRegistryAddress;
        delegateAddress             = _delegateAddress;
        maxRingSize                 = _maxRingSize;
        rateRatioCVSThreshold       = _rateRatioCVSThreshold;
    }


     
     
     

     
    function () payable {
        revert();
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitRing(
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList,
        address         ringminer,
        address         feeRecepient,
        bool            throwIfLRCIsInsuffcient
        )
        public {

        (!entered).orThrow("attepted to re-ent submitRing function");
        entered = true;

         
        uint ringSize = addressList.length;
        (ringSize > 1 && ringSize <= maxRingSize)
            .orThrow("invalid ring size");

        verifyInputDataIntegrity(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList);

        verifyTokensRegistered(addressList);


        var ringhashRegistry = RinghashRegistry(ringhashRegistryAddress);

        bytes32 ringhash = ringhashRegistry.calculateRinghash(
            ringSize,
             
             
            vList,
            rList,
            sList
        );

        ringhashRegistry.canSubmit(ringhash, feeRecepient)
            .orThrow("Ring claimed by others");

        verifySignature(
            ringminer,
            ringhash,
            vList[ringSize],
            rList[ringSize],
            sList[ringSize]
        );

         
        var orders = assembleOrders(
            ringSize,
            addressList,
            uintArgsList,
            uint8ArgsList,
            buyNoMoreThanAmountBList,
            vList,
            rList,
            sList);

        if (feeRecepient == address(0)) {
            feeRecepient = ringminer;
        }

        handleRing(
            ringhash,
            orders,
            ringminer,
            feeRecepient,
            throwIfLRCIsInsuffcient
        );

        entered = true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function cancelOrder(
        address[3] addresses,
        uint[7]    orderValues,
        bool       buyNoMoreThanAmountB,
        uint8      marginSplitPercentage,
        uint8      v,
        bytes32    r,
        bytes32    s
        )
        public {

        uint cancelAmount = orderValues[6];
        (cancelAmount > 0).orThrow("amount to cancel is zero");

        var order = Order(
            addresses[0],
            addresses[1],
            addresses[2],
            orderValues[0],
            orderValues[1],
            orderValues[2],
            orderValues[3],
            orderValues[4],
            orderValues[5],
            buyNoMoreThanAmountB,
            marginSplitPercentage,
            v,
            r,
            s
        );

        bytes32 orderHash = calculateOrderHash(order);
        cancelled[orderHash] = cancelled[orderHash].add(cancelAmount);

        OrderCancelled(
            block.timestamp,
            block.number,
            orderHash,
            cancelAmount
        );
    }


     
     
     
     
     
    function setCutoff(uint cutoff) public {
        uint t = cutoff;
        if (t == 0) {
            t = block.timestamp;
        }

        (cutoffs[msg.sender] < t)
            .orThrow("attempted to set cutoff to a smaller value");

        cutoffs[msg.sender] = t;

        CutoffTimestampChanged(
            block.timestamp,
            block.number,
            msg.sender,
            t
        );
    }


     
     
     

     
    function verifyRingHasNoSubRing(Ring ring)
        internal
        constant {

        uint ringSize = ring.orders.length;
         
        for (uint i = 0; i < ringSize -1; i++) {
            address tokenS = ring.orders[i].order.tokenS;
            for (uint j = i + 1; j < ringSize; j++){
                 (tokenS != ring.orders[j].order.tokenS)
                    .orThrow("found sub-ring");
            }
        }
    }

    function verifyTokensRegistered(address[2][] addressList) internal constant {
        var registryContract = TokenRegistry(tokenRegistryAddress);
        for (uint i = 0; i < addressList.length; i++) {
            registryContract.isTokenRegistered(addressList[i][1])
                .orThrow("token not registered");
        }
    }

    function handleRing(
        bytes32 ringhash,
        OrderState[] orders,
        address miner,
        address feeRecepient,
        bool throwIfLRCIsInsuffcient
        )
        internal {
        var ring = Ring(
            ringhash,
            orders,
            miner,
            feeRecepient,
            throwIfLRCIsInsuffcient);

         
        verifyRingHasNoSubRing(ring);

         
         
         
        verifyMinerSuppliedFillRates(ring);

         
         
         
        scaleRingBasedOnHistoricalRecords(ring);

         
         
         
         
        calculateRingFillAmount(ring);

         
         
         
        calculateRingFees(ring);

         
        settleRing(ring);

        RingMined(
            ringIndex++,
            block.timestamp,
            block.number,
            ring.ringhash,
            ring.miner,
            ring.feeRecepient,
            RinghashRegistry(ringhashRegistryAddress).ringhashFound(ring.ringhash)
            );
    }

    function settleRing(Ring ring) internal {
        uint ringSize = ring.orders.length;
        var delegate = TokenTransferDelegate(delegateAddress);

        for (uint i = 0; i < ringSize; i++) {
            var state = ring.orders[i];
            var prev = ring.orders[i.prev(ringSize)];
            var next = ring.orders[i.next(ringSize)];

             
             

            delegate.transferToken(
                state.order.tokenS,
                state.order.owner,
                prev.order.owner,
                state.fillAmountS - prev.splitB);

            if (prev.splitB + state.splitS > 0) {
                delegate.transferToken(
                    state.order.tokenS,
                    state.order.owner,
                    ring.feeRecepient,
                    prev.splitB + state.splitS);
            }

             
            if (state.lrcReward > 0) {
                delegate.transferToken(
                    lrcTokenAddress,
                    ring.feeRecepient,
                    state.order.owner,
                    state.lrcReward);
            }

            if (state.lrcFee > 0) {
                 delegate.transferToken(
                    lrcTokenAddress,
                    state.order.owner,
                    ring.feeRecepient,
                    state.lrcFee);
            }

             
            if (state.order.buyNoMoreThanAmountB) {
                filled[state.orderHash] += next.fillAmountS;
            } else {
                filled[state.orderHash] += state.fillAmountS;
            }

            OrderFilled(
                ringIndex,
                block.timestamp,
                block.number,
                ring.ringhash,
                prev.orderHash,
                state.orderHash,
                next.orderHash,
                state.fillAmountS + state.splitS,
                next.fillAmountS - state.splitB,
                state.lrcReward,
                state.lrcFee
                );
        }

    }

    function verifyMinerSuppliedFillRates(Ring ring) internal constant {
        var orders = ring.orders;
        uint ringSize = orders.length;
        uint[] memory rateRatios = new uint[](ringSize);

        for (uint i = 0; i < ringSize; i++) {
            uint rateAmountB = orders[i.next(ringSize)].rateAmountS;

            uint s1b0 = orders[i].rateAmountS.mul(orders[i].order.amountB);
            uint s0b1 = orders[i].order.amountS.mul(rateAmountB);

            (s1b0 <= s0b1)
                .orThrow("miner supplied exchange rate provides invalid discount");

            rateRatios[i] = RATE_RATIO_SCALE.mul(s1b0).div(s0b1);
        }

        uint cvs = UintLib.cvsquare(rateRatios, RATE_RATIO_SCALE);

        (cvs <= rateRatioCVSThreshold)
            .orThrow("miner supplied exchange rate is not evenly discounted");
    }

    function calculateRingFees(Ring ring) internal constant {
        uint minerLrcSpendable = getLRCSpendable(ring.feeRecepient);
        uint ringSize = ring.orders.length;

        for (uint i = 0; i < ringSize; i++) {
            var state = ring.orders[i];
            var next = ring.orders[i.next(ringSize)];

            if (state.feeSelection == FEE_SELECT_LRC) {

                uint lrcSpendable = getLRCSpendable(state.order.owner);

                if (lrcSpendable < state.lrcFee) {
                    (!ring.throwIfLRCIsInsuffcient)
                        .orThrow("order LRC balance insuffcient");

                    state.lrcFee = lrcSpendable;
                    minerLrcSpendable += lrcSpendable;
                }

            } else if (state.feeSelection == FEE_SELECT_MARGIN_SPLIT) {
                if (minerLrcSpendable >= state.lrcFee) {
                    if (state.order.buyNoMoreThanAmountB) {
                        uint splitS = next.fillAmountS
                            .mul(state.order.amountS)
                            .div(state.order.amountB)
                            .sub(state.fillAmountS);

                        state.splitS = splitS
                            .mul(state.order.marginSplitPercentage)
                            .div(MARGIN_SPLIT_PERCENTAGE_BASE);
                    } else {
                        uint splitB = next.fillAmountS.sub(
                            state.fillAmountS
                                .mul(state.order.amountB)
                                .div(state.order.amountS));

                        state.splitB = splitB
                            .mul(state.order.marginSplitPercentage)
                            .div(MARGIN_SPLIT_PERCENTAGE_BASE);
                    }

                     
                     
                     
                    if (state.splitS > 0 || state.splitB > 0) {
                        minerLrcSpendable = minerLrcSpendable.sub(state.lrcFee);
                        state.lrcReward = state.lrcFee;
                    }
                    state.lrcFee = 0;
                }
            } else {
                ErrorLib.error("unsupported fee selection value");
            }
        }

    }

    function calculateRingFillAmount(Ring ring) internal constant {

        uint ringSize = ring.orders.length;
        uint smallestIdx = 0;
        uint i;
        uint j;

        for (i = 0; i < ringSize; i++) {
            j = i.next(ring.orders.length);

            uint res = calculateOrderFillAmount(
                ring.orders[i],
                ring.orders[j]);

            if (res == 1) smallestIdx = i;
            else if (res == 2) smallestIdx = j;
        }

        for (i = 0; i < smallestIdx; i++) {
            j = i.next(ring.orders.length);
            (calculateOrderFillAmount(ring.orders[i], ring.orders[j]) == 0)
                .orThrow("unexpected exception in calculateRingFillAmount");
        }
    }

     
     
     
    function calculateOrderFillAmount(
        OrderState state,
        OrderState next
        )
        internal
        constant
        returns (uint state2IsSmaller) {

         
         
         
         
         
        uint fillAmountB  = next.rateAmountS
            .mul(state.fillAmountS)
            .div(state.rateAmountS);

        if (state.order.buyNoMoreThanAmountB) {
            if (fillAmountB > state.order.amountB) {
                fillAmountB = state.order.amountB;

                state.fillAmountS = state.rateAmountS
                    .mul(fillAmountB)
                    .div(next.rateAmountS);

                state2IsSmaller = 1;
            }

            state.lrcFee = state.order.lrcFee
                .mul(fillAmountB)
                .div(next.order.amountS);
        } else {
            state.lrcFee = state.order.lrcFee
                .mul(state.fillAmountS)
                .div(state.order.amountS);
        }

        if (fillAmountB <= next.fillAmountS) {
            next.fillAmountS = fillAmountB;
        } else {
            state2IsSmaller = 2;
        }
    }


     
     
    function scaleRingBasedOnHistoricalRecords(Ring ring) internal constant {

        uint ringSize = ring.orders.length;
        for (uint i = 0; i < ringSize; i++) {
            var state = ring.orders[i];
            var order = state.order;

            if (order.buyNoMoreThanAmountB) {
                uint amountB = order.amountB
                    .sub(filled[state.orderHash])
                    .tolerantSub(cancelled[state.orderHash]);

                order.amountS = amountB.mul(order.amountS).div(order.amountB);
                order.lrcFee = amountB.mul(order.lrcFee).div(order.amountB);

                order.amountB = amountB;
            } else {
                uint amountS = order.amountS
                    .sub(filled[state.orderHash])
                    .tolerantSub(cancelled[state.orderHash]);

                order.amountB = amountS.mul(order.amountB).div(order.amountS);
                order.lrcFee = amountS.mul(order.lrcFee).div(order.amountS);

                order.amountS = amountS;
            }

            (order.amountS > 0).orThrow("amountS is zero");
            (order.amountB > 0).orThrow("amountB is zero");

            state.fillAmountS = order.amountS.min256(state.availableAmountS);
        }
    }

     
    function getSpendable(
        address tokenAddress,
        address tokenOwner
        )
        internal
        constant
        returns (uint) {

        return TokenTransferDelegate(delegateAddress)
            .getSpendable(tokenAddress, tokenOwner);
    }

     
    function getLRCSpendable(address tokenOwner)
        internal
        constant
        returns (uint) {

        return getSpendable(lrcTokenAddress, tokenOwner);
    }

     
    function verifyInputDataIntegrity(
        uint ringSize,
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        internal
        constant {

        (ringSize == addressList.length)
            .orThrow("ring data is inconsistent - addressList");
        (ringSize == uintArgsList.length)
            .orThrow("ring data is inconsistent - uintArgsList");
        (ringSize == uint8ArgsList.length)
            .orThrow("ring data is inconsistent - uint8ArgsList");
        (ringSize == buyNoMoreThanAmountBList.length)
            .orThrow("ring data is inconsistent - buyNoMoreThanAmountBList");
        (ringSize + 1 == vList.length)
            .orThrow("ring data is inconsistent - vList");
        (ringSize + 1 == rList.length)
            .orThrow("ring data is inconsistent - rList");
        (ringSize + 1 == sList.length)
            .orThrow("ring data is inconsistent - sList");

         
        for (uint i = 0; i < ringSize; i++) {
            (uintArgsList[i][5] > 0).orThrow("order rateAmountS is zero");
            (uint8ArgsList[i][1] <= FEE_SELECT_MAX_VALUE).orThrow("invalid order fee selection ");
        }
    }

     
     
    function assembleOrders(
        uint            ringSize,
        address[2][]    addressList,
        uint[7][]       uintArgsList,
        uint8[2][]      uint8ArgsList,
        bool[]          buyNoMoreThanAmountBList,
        uint8[]         vList,
        bytes32[]       rList,
        bytes32[]       sList
        )
        internal
        constant
        returns (OrderState[]) {

        var orders = new OrderState[](ringSize);

        for (uint i = 0; i < ringSize; i++) {
            uint j = i.prev(ringSize);

            var order = Order(
                addressList[i][0],
                addressList[i][1],
                addressList[j][1],
                uintArgsList[i][0],
                uintArgsList[i][1],
                uintArgsList[i][2],
                uintArgsList[i][3],
                uintArgsList[i][4],
                uintArgsList[i][5],
                buyNoMoreThanAmountBList[i],
                uint8ArgsList[i][0],
                vList[i],
                rList[i],
                sList[i]);

            bytes32 orderHash = calculateOrderHash(order);

            verifySignature(
                order.owner,
                orderHash,
                order.v,
                order.r,
                order.s);

            validateOrder(order);

            orders[i] = OrderState(
                order,
                orderHash,
                uint8ArgsList[i][1],   
                uintArgsList[i][6],    
                getSpendable(order.tokenS, order.owner),
                0,    
                0,    
                0,    
                0,    
                0     
                );

             
             
        }

        return orders;
    }

     
    function validateOrder(Order order) internal constant {
        (order.owner != address(0))
            .orThrow("invalid order owner");
        (order.tokenS != address(0))
            .orThrow("invalid order tokenS");
        (order.tokenB != address(0))
            .orThrow("invalid order tokenB");
        (order.amountS > 0)
            .orThrow("invalid order amountS");
        (order.amountB > 0)
            .orThrow("invalid order amountB");
        (order.timestamp > cutoffs[order.owner])
            .orThrow("order is cut off");
        (order.ttl > 0)
            .orThrow("order ttl is 0");
        (order.timestamp + order.ttl > block.timestamp)
            .orThrow("order is expired");
        (order.salt > 0)
            .orThrow("invalid order salt");
        (order.marginSplitPercentage <= MARGIN_SPLIT_PERCENTAGE_BASE)
            .orThrow("invalid order marginSplitPercentage");
    }

     
    function calculateOrderHash(Order order)
        internal
        constant
        returns (bytes32) {

        return keccak256(
            address(this),
            order.tokenS,
            order.tokenB,
            order.amountS,
            order.amountB,
            order.timestamp,
            order.ttl,
            order.salt,
            order.lrcFee,
            order.buyNoMoreThanAmountB,
            order.marginSplitPercentage);
    }

     
    function verifySignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s)
        public
        constant
        {

        address addr = ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s);
        (signer == addr).orThrow("invalid signature");
    }

    function getOrderFilled(bytes32 orderHash)
        public
        constant
        returns (uint) {
        return filled[orderHash];
    }

    function getOrderCancelled(bytes32 orderHash)
        public
        constant
        returns (uint) {
        return cancelled[orderHash];
    }
}