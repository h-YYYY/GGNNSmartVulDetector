pragma solidity ^0.4.18;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) public pure returns(uint);

    function maxBalance() public pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        view
        returns(int);

    function serverForceGameEnd(
        uint8 gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);

    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);
}

contract ConflictResolution is ConflictResolutionInterface {
    uint public constant DICE_RANGE = 100;
    uint public constant HOUSE_EDGE = 150;
    uint public constant HOUSE_EDGE_DIVISOR = 10000;

    uint public constant SERVER_TIMEOUT = 2 days;
    uint public constant PLAYER_TIMEOUT = 1 days;

    uint8 public constant GAME_TYPE_DICE = 1;
    uint public constant MAX_BET_VALUE = 1e16;  
    uint public constant MIN_BET_VALUE = 1e13;  

    int public constant NOT_ENDED_FINE = 1e15;  

    int public constant MAX_BALANCE = int(MAX_BET_VALUE) * 100 * 5;

    modifier onlyValidBet(uint8 _gameType, uint _betNum, uint _betValue) {
        require(isValidBet(_gameType, _betNum, _betValue));
        _;
    }

    modifier onlyValidBalance(int _balance, uint _gameStake) {
         
        require(-int(_gameStake) <= _balance && _balance < MAX_BALANCE);
        _;
    }

     
    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool) {
        return (
            (_gameType == GAME_TYPE_DICE) &&
            (_betNum > 0 && _betNum < DICE_RANGE) &&
            (MIN_BET_VALUE <= _betValue && _betValue <= MAX_BET_VALUE)
        );
    }

     
    function maxBalance() public pure returns(int) {
        return MAX_BALANCE;
    }

     
    function minHouseStake(uint activeGames) public pure returns(uint) {
        return  MathUtil.min(activeGames, 1) * MAX_BET_VALUE * 400;
    }

     
    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        view
        onlyValidBet(_gameType, _betNum, _betValue)
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        assert(_serverSeed != 0 && _playerSeed != 0);

        int newBalance =  processDiceBet(_betNum, _betValue, _balance, _serverSeed, _playerSeed);

         
        int stake = int(_stake);
        if (newBalance < -stake) {
            newBalance = -stake;
        }

        return newBalance;
    }

     
    function serverForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        require(_endInitiatedTime + SERVER_TIMEOUT <= block.timestamp);
        require(isValidBet(_gameType, _betNum, _betValue)
                || (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0));


         
         
        int newBalance = _balance - int(_betValue);

         
        newBalance -= NOT_ENDED_FINE;

         
        int stake = int(_stake);
        if (newBalance < -stake) {
            newBalance = -stake;
        }

        return newBalance;
    }

     
    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint  _stake,
        uint _endInitiatedTime
    )
        public
        view
        onlyValidBalance(_balance, _stake)
        returns(int)
    {
        require(_endInitiatedTime + PLAYER_TIMEOUT <= block.timestamp);
        require(isValidBet(_gameType, _betNum, _betValue) ||
                (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0));

        int profit = 0;
        if (_gameType == 0 && _betNum == 0 && _betValue == 0 && _balance == 0) {
             
            profit = 0;
        } else {
            profit = calculateDiceProfit(_betNum, _betValue);
        }

         
        profit += NOT_ENDED_FINE;

        return _balance + profit;
    }

     
    function processDiceBet(
        uint _betNum,
        uint _betValue,
        int _balance,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        private
        pure
        returns (int)
    {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

         
        bool playerWon = calculateDiceWinner(_serverSeed, _playerSeed, _betNum);

        if (playerWon) {
            int profit = calculateDiceProfit(_betNum, _betValue);
            return _balance + profit;
        } else {
            return _balance - int(_betValue);
        }
    }

     
    function calculateDiceProfit(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

         
        uint betValue = _betValue / 1e9;

         
        uint totalWon = betValue * DICE_RANGE / _betNum;
        uint houseEdgeValue = totalWon * HOUSE_EDGE / HOUSE_EDGE_DIVISOR;
        int profit = int(totalWon) - int(houseEdgeValue) - int(betValue);

         
        return profit * 1e9;
    }

     
    function calculateDiceWinner(
        bytes32 _serverSeed,
        bytes32 _playerSeed,
        uint _betNum
    )
        private
        pure
        returns(bool)
    {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        bytes32 combinedHash = keccak256(_serverSeed, _playerSeed);
        uint randomNumber = uint(combinedHash) % DICE_RANGE;  
        return randomNumber < _betNum;
    }
}

library MathUtil {
     
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

     
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

     
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}