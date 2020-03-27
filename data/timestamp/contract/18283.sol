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

    uint public constant SERVER_TIMEOUT = 6 hours;
    uint public constant PLAYER_TIMEOUT = 6 hours;

    uint8 public constant DICE_LOWER = 1;  
    uint8 public constant DICE_HIGHER = 2;  

    uint public constant MAX_BET_VALUE = 2e16;  
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
        bool validValue = MIN_BET_VALUE <= _betValue && _betValue <= MAX_BET_VALUE;
        bool validGame = false;

        if (_gameType == DICE_LOWER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
        } else if (_gameType == DICE_HIGHER) {
            validGame = _betNum > 0 && _betNum < DICE_RANGE - 1;
        } else {
            validGame = false;
        }

        return validValue && validGame;
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

        int newBalance =  processBet(_gameType, _betNum, _betValue, _balance, _serverSeed, _playerSeed);

         
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
            profit = int(calculateProfit(_gameType, _betNum, _betValue));  
        }

         
        profit += NOT_ENDED_FINE;

        return _balance + profit;
    }

     
    function processBet(
        uint8 _gameType,
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
        bool won = hasPlayerWon(_gameType, _betNum, _serverSeed, _playerSeed);
        if (!won) {
            return _balance - int(_betValue);  
        } else {
            int profit = calculateProfit(_gameType, _betNum, _betValue);
            return _balance + profit;
        }
    }

     
    function calculateProfit(uint8 _gameType, uint _betNum, uint _betValue) private pure returns(int) {
        uint betValueInGwei = _betValue / 1e9;  
        int res = 0;

        if (_gameType == DICE_LOWER) {
            res = calculateProfitGameType1(_betNum, betValueInGwei);
        } else if (_gameType == DICE_HIGHER) {
            res = calculateProfitGameType2(_betNum, betValueInGwei);
        } else {
            assert(false);
        }
        return res * 1e9;  
    }

     
    function calcProfitFromTotalWon(uint _totalWon, uint _betValue) private pure returns(int) {
         
        uint houseEdgeValue = _totalWon * HOUSE_EDGE / HOUSE_EDGE_DIVISOR;

         
        return int(_totalWon) - int(houseEdgeValue) - int(_betValue);
    }

     
    function calculateProfitGameType1(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

         
        uint totalWon = _betValue * DICE_RANGE / _betNum;
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

     
    function calculateProfitGameType2(uint _betNum, uint _betValue) private pure returns(int) {
        assert(_betNum >= 0 && _betNum < DICE_RANGE - 1);

         
        uint totalWon = _betValue * DICE_RANGE / (DICE_RANGE - _betNum - 1);
        return calcProfitFromTotalWon(totalWon, _betValue);
    }

     
    function hasPlayerWon(
        uint8 _gameType,
        uint _betNum,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        private
        pure
        returns(bool)
    {
        bytes32 combinedHash = keccak256(_serverSeed, _playerSeed);
        uint randNum = uint(combinedHash);

        if (_gameType == 1) {
            return calculateWinnerGameType1(randNum, _betNum);
        } else if (_gameType == 2) {
            return calculateWinnerGameType2(randNum, _betNum);
        } else {
            assert(false);
        }
    }

     
    function calculateWinnerGameType1(uint _randomNum, uint _betNum) private pure returns(bool) {
        assert(_betNum > 0 && _betNum < DICE_RANGE);

        uint resultNum = _randomNum % DICE_RANGE;  
        return resultNum < _betNum;
    }

     
    function calculateWinnerGameType2(uint _randomNum, uint _betNum) private pure returns(bool) {
        assert(_betNum >= 0 && _betNum < DICE_RANGE - 1);

        uint resultNum = _randomNum % DICE_RANGE;  
        return resultNum > _betNum;
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