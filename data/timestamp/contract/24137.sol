pragma solidity ^0.4.17;
contract AbstractRegistration {
     
    function getRegistration() public view returns(string, address, string, string, uint, string, string, address[5], uint[5]);
}

contract BaseRegistration is AbstractRegistration{
    address public owner; 
    string public songTitle;  
    string public hash;  
    string public digitalSignature;  
    string public professionalName;  
    string public duration;  
    string dateOfPublish;  
    uint rtype;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function BaseRegistration() public{
        owner = msg.sender;
    }
    
     
     
    function getOwnerAddress() external constant returns (address){
        return owner;
    }
    
     
     
    function changeOwnerAddress(address _owner) onlyOwner internal {
        require(_owner != 0x0);
        require(owner != _owner);
        owner = _owner;
    }
    
     
    function getRegistration() public view returns(string, address, string, string, uint, string, string, address[5], uint[5]){}
}

contract SongRecordingRegistration is BaseRegistration{
    uint constant MAX_ROYALTY = 5;
    
    uint totalPercent = 0;  
    uint countRoyaltyPartner;  
    address addressDispute;  
    address addrMultiSign;  
    
     
    struct RoyaltyPartner{
        uint percent;
        bool confirmed;
        bool exists;
    }
    
    mapping(uint => address) royaltyIndex;  
    mapping(address => RoyaltyPartner) royaltyPartners;
    
     
     
    function  SongRecordingRegistration(
        string _songTitle,
        string _hash,
        string _digital,
        address _addrDispute,
        string _dateOfPublish,
        address _addrMultiSign,
        string _professionalName,
        string _duration,
        uint[] _arrRoyaltyPercent,
        address[] _arrRoyaltyAddress) public{
        songTitle = _songTitle;
        hash = _hash;
        rtype = 1;
        digitalSignature = _digital;
        dateOfPublish = _dateOfPublish;
        addrMultiSign = _addrMultiSign;
        professionalName = _professionalName;
        duration = _duration;
        checkingDispute(_addrDispute, address(this));
        assert(_arrRoyaltyAddress.length == _arrRoyaltyPercent.length);
        assert(_arrRoyaltyPercent.length <= uint(MAX_ROYALTY));
        for (uint i = 0; i < _arrRoyaltyAddress.length; i++){
            require(_arrRoyaltyAddress[i] != owner);
            require(totalPercent <= 100);
            royaltyIndex[i] = _arrRoyaltyAddress[i];
            royaltyPartners[_arrRoyaltyAddress[i]] = RoyaltyPartner(_arrRoyaltyPercent[i], false, true);
            totalPercent += _arrRoyaltyPercent[i];
            countRoyaltyPartner++;
        }
    }
    
     
     
    function getRegistration() public view returns(string _songTitle, address _owner, string _hash, string _digital, uint _type, string _professionalName, string _duration, address[5] _arrRoyaltyAddress, uint[5] _arrRoyaltyPercent){
        _owner = owner;
        _songTitle = songTitle;
        _hash = hash;
        _digital = digitalSignature;
        _type = rtype;
        _duration = duration;
        _professionalName = professionalName;
        for (uint i=0; i<5; i++){
            _arrRoyaltyAddress[i] = royaltyIndex[i];
            _arrRoyaltyPercent[i] = royaltyPartners[_arrRoyaltyAddress[i]].percent;
        }
        return (_songTitle, _owner, _hash, _digital, _type, _professionalName, _duration, _arrRoyaltyAddress, _arrRoyaltyPercent);
    }
    
     
     
    function getRoyaltyPercent(address _toRoyaltyPartner) public constant returns(uint) {
        return royaltyPartners[_toRoyaltyPartner].percent;
    }
    
     
     
    function getRoyaltyExists(address _toRoyaltyPartner) public constant returns(bool){
        return royaltyPartners[_toRoyaltyPartner].exists;
    }
    
     
     
    function getTotalPercent() external constant returns(uint){
        return totalPercent;
    }
    
     
     
    function getRoyaltyPartners() public constant returns(address[5] _arrRoyaltyAddress, uint[5] _arrRoyaltyPercent){
        for (uint i = 0; i < MAX_ROYALTY; i++){
            _arrRoyaltyAddress[i] = royaltyIndex[i];
            _arrRoyaltyPercent[i] = royaltyPartners[royaltyIndex[i]].percent;
        }
        return (_arrRoyaltyAddress, _arrRoyaltyPercent);
    }
    
     
     
    function changeRoyaltyPercent(
        address _toRoyaltyPartner, 
        uint _percent,
        bool _exists) public{
        require(msg.sender == addrMultiSign);  
        if(!_exists){
            royaltyPartners[_toRoyaltyPartner] = RoyaltyPartner(_percent, false, true);
            royaltyIndex[countRoyaltyPartner] = _toRoyaltyPartner;
            totalPercent += _percent;
            countRoyaltyPartner++;
        }else{
            totalPercent = totalPercent - getRoyaltyPercent(_toRoyaltyPartner) + _percent;
            royaltyPartners[_toRoyaltyPartner].percent = _percent;
        }
    }
    
     
     
    function checkingDispute(address _addrDispute, address _addrCurrent) public {
        if(_addrDispute != address(0)){
            addressDispute = _addrDispute;
            SongRecordingRegistration musicReg = SongRecordingRegistration(_addrDispute);
            assert(musicReg.getDispute() == address(0));
            musicReg.setDispute(_addrCurrent);
        }
    }
    
     
     
    function setDispute(address _addrDispute) public{
        addressDispute = _addrDispute;
    }
    
     
     
    function getDispute() public constant returns(address){
        return addressDispute;
    }
}

contract WorkRegistration is BaseRegistration{
    bool isTempRegistration = false;  
    
     
    function WorkRegistration(
        string _songTitle,
        string _hash,
        string _digital,
        string _dateOfPublish,
        bool _isTempRegistration) public{
        songTitle = _songTitle;
        hash = _hash;
        rtype = 2;
        digitalSignature = _digital;
        isTempRegistration = _isTempRegistration;
        dateOfPublish = _dateOfPublish;
    }
    
     
     
    function getRegistration() public view returns(string _songTitle, address _owner, string _hash, string _digital, uint _type, string _professionalName, string, address[5], uint[5]){
        _owner = owner;
        _songTitle = songTitle;
        _hash = hash;
        _digital = digitalSignature;
        _type = rtype;
        _professionalName = "";
    }
    
     
     
    function getComposer() external constant returns(
        string _hash,
        string _digital,
        bool _isTempRegistration){
        _hash = hash;
        _digital = digitalSignature;
        _isTempRegistration = isTempRegistration;
    }
    
     
     
    function setTempRegistration(bool _isTempRegistration) onlyOwner public{
        isTempRegistration = _isTempRegistration;
    }
}

contract Licensing {
     
    enum licensedState { Pending, Expired , Licensed }
    
     
     
    uint constant ExpiryTime = 30*24*60*60; 
    
    address  token;  
    address  buyAddress;  
    address  songAddress;  
    string  territority;
    string  right;  
    uint  period;  
    uint256 dateIssue;  
    bool  isCompleted;  
    uint price;  
    string hashOfLicense;  
    
    modifier onlyOwner() {
        require(msg.sender == buyAddress);
        _;
    }
    
    modifier onlyOwnerOfSong(){
        SongRecordingRegistration musicContract = SongRecordingRegistration(songAddress);
        require(msg.sender == musicContract.getOwnerAddress());
        _;
    }
    
     
    function Licensing(
        address _token,
        address addressOfSong, 
        string territorityOfLicense, 
        string rightOfLicense, 
        uint periodOfLicense,
        string _hashOfLicense) public{
        buyAddress = msg.sender;
        songAddress = addressOfSong;
        territority = territorityOfLicense;
        right = rightOfLicense;
        period = periodOfLicense;
        hashOfLicense = _hashOfLicense;
        isCompleted = false;
        dateIssue = block.timestamp;
        token = _token;
    }

     
     
    function getStatus() constant private returns (licensedState){
        if(isCompleted == true){
            return licensedState.Licensed;
        }else {
            if(block.timestamp >  (dateIssue + ExpiryTime)){
                return licensedState.Expired;
            }else{
                return licensedState.Pending;
            }
        }
    }
    
     
     
    function getContractStatus() constant public returns (string){
        licensedState currentState = getStatus();
        if(currentState == licensedState.Pending){
            return "Pending";
        }else if(currentState == licensedState.Expired){
            return "Expired";
        }else {
            return "Licensed";
        }
    }
    
     
     
     
    function updatePrice(uint priceOfLicense) onlyOwnerOfSong public{
        
         
        assert(!isCompleted);
         
        assert (priceOfLicense > 0);
        assert (block.timestamp <  (dateIssue + ExpiryTime));
        
         
        price = priceOfLicense;
    }
    
     
     
    function getContractAddress() external constant returns (address){
        return this;
    }
    
     
     
    function getOwnerAddress() external constant returns(address){
        return(buyAddress);
    }
    
     
     
    function upgradeCompleted(bool _isCompleted) public{
        require(_isCompleted);
        require(price >0);
        require(msg.sender == token);
        isCompleted = _isCompleted;
    }
    
     
     
    function checkPrice(uint256 _price) public constant returns(bool){
        require(msg.sender == token);
        return (_price >= price) ? true : false;
    }
}