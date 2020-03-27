pragma solidity ^0.4.11;

contract Factory {
  address developer = 0x007C67F0CDBea74592240d492Aef2a712DAFa094c3;
  
  event ContractCreated(address creator, address newcontract, uint timestamp, string contract_type);
    
  function setDeveloper (address _dev) public {
    if(developer==address(0) || developer==msg.sender){
       developer = _dev;
    }
  }
  
  function createContract (bool isbroker, string contract_type, bool _brokerrequired) 
  public {
    address newContract = new Broker(isbroker, developer, msg.sender, _brokerrequired);
    emit ContractCreated(msg.sender, newContract, block.timestamp, contract_type);
  } 
}

contract Broker {
  enum State { Created, Validated, Locked, Finished }
  State public state;

  enum FileState { 
    Created, 
    Invalidated
     
  }

  struct File{
     
     
     
    bytes32 purpose;
     
    string name;
     
    string ipfshash;
    FileState state;
  }

  struct Item{
    string name;
     
    uint   price;
     
    string detail;
    File[] documents;
  }

  Item public item;
  address public seller = address(0);
  address public broker = address(0);
  uint    public brokerFee;
   
  uint    public developerfee = 0.1 finney;
  uint    minimumdeveloperfee = 0.1 finney;
  address developer = 0x007C67F0CDBea74592240d492Aef2a712DAFa094c3;
   
  address creator = 0x0;
  address factory = 0x0;
  
  bool bBrokerRequired = true;
  address[] public buyers;


  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  modifier onlyBroker() {
    require(msg.sender == broker);
    _;
  }

  modifier inState(State _state) {
      require(state == _state);
      _;
  }

  modifier condition(bool _condition) {
      require(_condition);
      _;
  }

  event AbortedBySeller();
  event AbortedByBroker();
  event PurchaseConfirmed(address buyer);
  event ItemReceived();
  event Validated();
  event ItemInfoChanged(string name, uint price, string detail, uint developerfee);
  event SellerChanged(address seller);
  event BrokerChanged(address broker);
  event BrokerFeeChanged(uint fee);

   
  constructor(bool isbroker, address _dev, address _creator, bool _brokerrequired) 
    public 
  {
    bBrokerRequired = _brokerrequired;
    if(creator==address(0)){
       
      if(isbroker)
        broker = _creator;
      else
        seller = _creator;
      creator = _creator;
       
       
      state = State.Created;

       
      brokerFee = 50;
    }
    if(developer==address(0) || developer==msg.sender){
       developer = _dev;
    }
    if(factory==address(0)){
       factory = msg.sender;
    }
  }

  function joinAsBroker() public {
    if(broker==address(0)){
      broker = msg.sender;
    }
  }

  function createOrSet(string name, uint price, string detail)
    public 
    inState(State.Created)
    onlyCreator
  {
    require(price > minimumdeveloperfee);
    item.name = name;
    item.price = price;
    item.detail = detail;
    developerfee = (price/1000)<minimumdeveloperfee ? minimumdeveloperfee : (price/1000);
    emit ItemInfoChanged(name, price, detail, developerfee);
  }

  function getBroker()
    public 
    constant returns(address, uint)
  {
    return (broker, brokerFee);
  }

  function getSeller()
    public 
    constant returns(address)
  {
    return (seller);
  }
  
  function getBuyers()
    public 
    constant returns(address[])
  {
    return (buyers);
  }

  function setBroker(address _address)
    public 
    onlySeller
    inState(State.Created)
  {
    broker = _address;
    emit BrokerChanged(broker);
  }

  function setBrokerFee(uint fee)
    public 
    onlyCreator
    inState(State.Created)
  {
    brokerFee = fee;
    emit BrokerFeeChanged(fee);
  }

  function setSeller(address _address)
    public 
    onlyBroker
    inState(State.Created)
  {
    seller = _address;
    emit SellerChanged(seller);
  }

   
   
   
   
   
   
   
  function addDocument(bytes32 _purpose, string _name, string _ipfshash)
    public 
  {
    require(state != State.Finished);
    require(state != State.Locked);
    item.documents.push( File({
      purpose:_purpose, name:_name, ipfshash:_ipfshash, state:FileState.Created}
      ) 
    );
  }

   
  function deleteDocument(uint index)
    public 
  {
    require(state != State.Finished);
    require(state != State.Locked);
    if(index<item.documents.length){
      item.documents[index].state = FileState.Invalidated;
    }
  }

  function validate()
    public 
    onlyBroker
    inState(State.Created)
  {
     
     
     
    emit Validated();
     
    state = State.Validated;
  }

   
   
   
  function abort()
    public 
    onlySeller
    inState(State.Created)
  {
      emit AbortedBySeller();
      state = State.Finished;
       
      seller.transfer(address(this).balance);
  }

  function abortByBroker()
    public 
    onlyBroker
  {
      if(!bBrokerRequired)
        return;
        
      require(state != State.Finished);
      state = State.Finished;
      emit AbortedByBroker();
      
      if(buyers.length>0){
          uint val = address(this).balance / buyers.length;
          for (uint256 x = 0; x < buyers.length; x++) {
              buyers[x].transfer(val);
          }
      }
  }

   
   
   
  function confirmPurchase()
    public 
    condition(msg.value == item.price)
    payable
  {
      if(bBrokerRequired){
        if(state != State.Validated){
          return;
        }
      }
      
      state = State.Locked;
      buyers.push(msg.sender);
      emit PurchaseConfirmed(msg.sender);
      
      if(!bBrokerRequired){
		 
        seller.transfer(item.price-developerfee);
        developer.transfer(developerfee);
      }
  }

   
   
  function confirmReceived()
    public 
    onlyBroker
    inState(State.Locked)
  {
       
       
       
      state = State.Finished;

       
       
      seller.transfer(address(this).balance-brokerFee-developerfee);
      broker.transfer(brokerFee);
      developer.transfer(developerfee);

      emit ItemReceived();
  }

  function getInfo() constant 
    public 
    returns (State, string, uint, string, uint, uint, address, address, bool)
  {
    return (state, item.name, item.price, item.detail, item.documents.length, 
        developerfee, seller, broker, bBrokerRequired);
  }

  function getFileAt(uint index) 
    public 
    constant returns(uint, bytes32, string, string, FileState)
  {
    return (index,
      item.documents[index].purpose,
      item.documents[index].name,
      item.documents[index].ipfshash,
      item.documents[index].state);
  }
}