pragma solidity ^0.4.24;


 
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

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 
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


 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}


 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}


 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

     
     
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from].length--;
     

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}


contract TTTToken {
  function transfer(address _to, uint256 _amount) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
}


 
 
 
contract TTTSan is ERC721Token, Ownable {

  address public wallet = 0x515165A6511734A4eFB5Cfb531955cf420b2725B;
  address public tttTokenAddress = 0x24358430f5b1f947B04D9d1a22bEb6De01CaBea2;
  address public marketAddress;

  uint256 public sanTTTCost;
  uint256 public sanMaxLength;
  uint256 public sanMinLength;
  uint256 public sanMaxAmount;
  uint256 public sanMaxFree;
  uint256 public sanCurrentTotal;

  string public baseUrl = "https://thetiptoken.io/arv/img/";

  mapping(string=>bool) sanOwnership;
  mapping(address=>uint256) sanSlots;
  mapping(address=>uint256) sanOwnerAmount;
  mapping(string=>uint256) sanNameToId;
  mapping(string=>address) sanNameToAddress;

  struct SAN {
    string sanName;
    uint256 timeAlive;
    uint256 timeLastMove;
    address prevOwner;
    string sanageLink;
  }

  SAN[] public sans;

  TTTToken ttt;

  modifier isMarketAddress() {
		require(msg.sender == marketAddress);
		_;
	}

  event SanMinted(address sanOwner, uint256 sanId, string sanName);
  event SanSlotPurchase(address sanOwner, uint256 amt);
  event SanCostUpdated(uint256 cost);
  event SanLengthReqChange(uint256 sanMinLength, uint256 sanMaxLength);
  event SanMaxAmountChange(uint256 sanMaxAmount);

  constructor() public ERC721Token("TTTSAN", "TTTS") {
    sanTTTCost = 10 ether;
    sanMaxLength = 16;
    sanMinLength = 2;
    sanMaxAmount = 100;
    sanMaxFree = 500;
    ttt = TTTToken(tttTokenAddress);
     
   
    string memory gen0 = "NeverGonnaGiveYouUp.NeverGonnaLetYouDown";
    SAN memory s = SAN({
        sanName: gen0,
        timeAlive: block.timestamp,
        timeLastMove: block.timestamp,
        prevOwner: msg.sender,
        sanageLink: "0x"
    });
    uint256 sanId = sans.push(s).sub(1);
    sanOwnership[gen0] = true;
    _sanMint(sanId, msg.sender, "gen0.jpeg", gen0);
  }

  function sanMint(string _sanName, string _sanageUri) external returns (string) {
     
    if(sanCurrentTotal > sanMaxFree)
      require(sanSlots[msg.sender] >= 1, "no san slots available");
    string memory sn = sanitize(_sanName);
    SAN memory s = SAN({
        sanName: sn,
        timeAlive: block.timestamp,
        timeLastMove: block.timestamp,
        prevOwner: msg.sender,
        sanageLink: _sanageUri
    });
    uint256 sanId = sans.push(s).sub(1);
    sanOwnership[sn] = true;
    if(sanCurrentTotal > sanMaxFree)
      sanSlots[msg.sender] = sanSlots[msg.sender].sub(1);
    _sanMint(sanId, msg.sender, _sanageUri, sn);
    return sn;
  }

  function getSANOwner(uint256 _sanId) public view returns (address) {
    return ownerOf(_sanId);
  }

  function getSanIdFromName(string _sanName) public view returns (uint256) {
    return sanNameToId[_sanName];
  }

  function getSanName(uint256 _sanId) public view returns (string) {
    return sans[_sanId].sanName;
  }

  function getSanageLink(uint256 _sanId) public view returns (string) {
    return sans[_sanId].sanageLink;
  }

  function getSanTimeAlive(uint256 _sanId) public view returns (uint256) {
    return sans[_sanId].timeAlive;
  }

  function getSanTimeLastMove(uint256 _sanId) public view returns (uint256) {
    return sans[_sanId].timeLastMove;
  }

  function getSanPrevOwner(uint256 _sanId) public view returns (address) {
    return sans[_sanId].prevOwner;
  }

  function getAddressFromSan(string _sanName) public view returns (address) {
    return sanNameToAddress[_sanName];
  }

  function getSanSlots(address _sanOwner) public view returns(uint256) {
    return sanSlots[_sanOwner];
  }

   
  function getSANitized(string _sanName) external view returns (string) {
    return sanitize(_sanName);
  }

  function buySanSlot(address _sanOwner,  uint256 _tip) external returns(bool) {
    require(_tip >= sanTTTCost, "tip less than san cost");
    require(sanSlots[_sanOwner] < sanMaxAmount, "max san slots owned");
    sanSlots[_sanOwner] = sanSlots[_sanOwner].add(1);
    ttt.transferFrom(msg.sender, wallet, _tip);
    emit SanSlotPurchase(_sanOwner, 1);
    return true;
  }

  function marketSale(uint256 _sanId, string _sanName, address _prevOwner, address _newOwner) external isMarketAddress {
    SAN storage s = sans[_sanId];
    s.prevOwner = _prevOwner;
    s.timeLastMove = block.timestamp;
    sanNameToAddress[_sanName] = _newOwner;
     
    if(sanCurrentTotal > sanMaxFree) {
      sanSlots[_prevOwner] = sanSlots[_prevOwner].sub(1);
      sanSlots[_newOwner] = sanSlots[_newOwner].add(1);
    }
    sanOwnerAmount[_prevOwner] = sanOwnerAmount[_prevOwner].sub(1);
    sanOwnerAmount[_newOwner] = sanOwnerAmount[_newOwner].add(1);
  }

  function() public payable { revert(); }

   

  function setSanTTTCost(uint256 _cost) external onlyOwner {
    sanTTTCost = _cost;
    emit SanCostUpdated(sanTTTCost);
  }

  function setSanLength(uint256 _length, uint256 _pos) external onlyOwner {
    require(_length > 0);
    if(_pos == 0) sanMinLength = _length;
    else sanMaxLength = _length;
    emit SanLengthReqChange(sanMinLength, sanMaxLength);
  }

  function setSanMaxAmount(uint256 _amount) external onlyOwner {
    sanMaxAmount = _amount;
    emit SanMaxAmountChange(sanMaxAmount);
  }

  function setSanMaxFree(uint256 _sanMaxFree) external onlyOwner {
    sanMaxFree = _sanMaxFree;
  }

  function ownerAddSanSlot(address _sanOwner, uint256 _slotCount) external onlyOwner {
    require(_slotCount > 0 && _slotCount <= sanMaxAmount);
    require(sanSlots[_sanOwner] < sanMaxAmount);
    sanSlots[_sanOwner] = sanSlots[_sanOwner].add(_slotCount);
  }

   
  function ownerAddSanSlotBatch(address[] _sanOwner, uint256[] _slotCount) external onlyOwner {
    require(_sanOwner.length == _slotCount.length);
    require(_sanOwner.length <= 100);
    for(uint8 i = 0; i < _sanOwner.length; i++) {
      require(_slotCount[i] > 0 && _slotCount[i] <= sanMaxAmount, "incorrect slot count");
      sanSlots[_sanOwner[i]] = sanSlots[_sanOwner[i]].add(_slotCount[i]);
      require(sanSlots[_sanOwner[i]] <= sanMaxAmount, "max san slots owned");
    }
  }

  function setMarketAddress(address _marketAddress) public onlyOwner {
    marketAddress = _marketAddress;
  }

  function setBaseUrl(string _baseUrl) public onlyOwner {
    baseUrl = _baseUrl;
  }

  function setOwnerWallet(address _wallet) public onlyOwner {
    wallet = _wallet;
  }

  function updateTokenUri(uint256 _sanId, string _newUri) public onlyOwner {
    SAN storage s = sans[_sanId];
    s.sanageLink = _newUri;
    _setTokenURI(_sanId, strConcat(baseUrl, _newUri));
  }

  function emptyTTT() external onlyOwner {
    ttt.transfer(msg.sender, ttt.balanceOf(address(this)));
  }

  function emptyEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }

   
  function specialSanMint(string _sanName, string _sanageUri, address _address) external onlyOwner returns (string) {
    SAN memory s = SAN({
        sanName: _sanName,
        timeAlive: block.timestamp,
        timeLastMove: block.timestamp,
        prevOwner: _address,
        sanageLink: _sanageUri
    });
    uint256 sanId = sans.push(s).sub(1);
    _sanMint(sanId, _address, _sanageUri, _sanName);
    return _sanName;
  }

   

  function sanitize(string _sanName) internal view returns(string) {
    string memory sn = sanToLower(_sanName);
    require(isValidSan(sn), "san is not valid");
    require(!sanOwnership[sn], "san is not unique");
    return sn;
  }

  function _sanMint(uint256 _sanId, address _owner, string _sanageUri, string _sanName) internal {
    require(sanOwnerAmount[_owner] < sanMaxAmount, "max san owned");
    sanNameToId[_sanName] = _sanId;
    sanNameToAddress[_sanName] = _owner;
    sanOwnerAmount[_owner] = sanOwnerAmount[_owner].add(1);
    sanCurrentTotal = sanCurrentTotal.add(1);
    _mint(_owner, _sanId);
    _setTokenURI(_sanId, strConcat(baseUrl, _sanageUri));
    emit SanMinted(_owner, _sanId, _sanName);
  }

  function isValidSan(string _sanName) internal view returns(bool) {
    bytes memory wb = bytes(_sanName);
    uint slen = wb.length;
    if (slen > sanMaxLength || slen <= sanMinLength) return false;
    bytes1 space = bytes1(0x20);
    bytes1 period = bytes1(0x2E);
     
    bytes1 e = bytes1(0x65);
    bytes1 t = bytes1(0x74);
    bytes1 h = bytes1(0x68);
    uint256 dCount = 0;
    uint256 eCount = 0;
    uint256 eth = 0;
    for(uint256 i = 0; i < slen; i++) {
        if(wb[i] == space) return false;
        else if(wb[i] == period) {
          dCount = dCount.add(1);
           
          if(dCount > 1) return false;
          eCount = 1;
        } else if(eCount > 0 && eCount < 5) {
          if(eCount == 1) if(wb[i] == e) eth = eth.add(1);
          if(eCount == 2) if(wb[i] == t) eth = eth.add(1);
          if(eCount == 3) if(wb[i] == h) eth = eth.add(1);
          eCount = eCount.add(1);
        }
    }
    if(dCount == 0) return false;
    if((eth == 3 && eCount == 4) || eCount == 1) return false;
    return true;
  }

  function sanToLower(string _sanName) internal pure returns(string) {
    bytes memory b = bytes(_sanName);
    for(uint256 i = 0; i < b.length; i++) {
      b[i] = byteToLower(b[i]);
    }
    return string(b);
  }

  function byteToLower(bytes1 _b) internal pure returns (bytes1) {
    if(_b >= bytes1(0x41) && _b <= bytes1(0x5A))
      return bytes1(uint8(_b) + 32);
    return _b;
  }

  function strConcat(string _a, string _b) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length.add(_bb.length));
    bytes memory bab = bytes(ab);
    uint256 k = 0;
    for (uint256 i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

}