 
 
pragma solidity ^0.4.24;

 
contract ERC20Basic
{
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MultiSig
{
  address constant internal CONTRACT_SIGNATURE1 = 0xa5a5f62BfA22b1E42A98Ce00131eA658D5E29B37;  
  address constant internal CONTRACT_SIGNATURE2 = 0x9115a6162D6bC3663dC7f4Ea46ad87db6B9CB926;  
  
  mapping(address => uint256) internal mSignatures;
  mapping(address => uint256) internal mLastSpend;
  
   
  uint256 public GAS_PRICE_LIMIT = 200 * 10**9;                        
  
   
  uint256 public constant WHOLE_ETHER = 10**18;
  uint256 public constant FRACTION_ETHER = 10**14;
  uint256 public constant COSIGN_MAX_TIME= 900;  
  uint256 public constant DAY_LENGTH  = 300;  
  
   
  uint256 public constant MAX_DAILY_SOLO_SPEND = (5*WHOLE_ETHER);  
  uint256 public constant MAX_DAILY_COSIGN_SEND = (500*WHOLE_ETHER);
  
   
  uint256 public constant MAX_DAILY_TOKEN_SOLO_SPEND = 2500000*WHOLE_ETHER;  
  uint256 public constant MAX_DAILY_TOKEN_COSIGN_SPEND = 250000000*WHOLE_ETHER;  
  
  uint256 internal mAmount1=0;
  uint256 internal mAmount2=0;

   
  function sendsignature() internal
  {
        
        require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2)); 
        
         
        uint256 timestamp = block.timestamp;
        mSignatures[msg.sender] = timestamp;
  }
  
   
  function SetGasLimit(uint256 newGasLimit) public
  {
      require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2)); 
      GAS_PRICE_LIMIT = newGasLimit;                        
  }
    
   
  function spendlarge(uint256 _to, uint256 _main, uint256 _fraction) public returns (bool valid)
  {
        require( _to != 0x0); 
        require( _main<= MAX_DAILY_COSIGN_SEND); 
        require( _fraction< (WHOLE_ETHER/FRACTION_ETHER)); 
        require (tx.gasprice <= GAS_PRICE_LIMIT); 
         
        sendsignature();
        
        uint256 currentTime = block.timestamp;
        uint256 valid1=0;
        uint256 valid2=0;
        
         
         
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE1] < COSIGN_MAX_TIME)
        {
            mAmount1 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid1=1;
        }
        
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE2] < COSIGN_MAX_TIME)
        {
            mAmount2 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid2=1;
        }
        
        if (valid1==1 && valid2==1)  
        {
             
            require( (currentTime - mLastSpend[msg.sender]) > DAY_LENGTH); 
        
            if (mAmount1 == mAmount2)
            {
                 
                address(_to).transfer(mAmount1);
                
                 
                valid1=0;
                valid2=0;
                mAmount1=0;
                mAmount2=0;
                
                 
                endsigning();
                
                return true;
            }
        }
        
         
        return false;
  }
  
   
  function takedaily(address _to) public returns (bool valid)
  {
    require( _to != 0x0); 
    require (tx.gasprice <= GAS_PRICE_LIMIT); 
    
     
    require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2)); 
        
    uint256 currentTime = block.timestamp;
        
     
    require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH); 
    
     
    _to.transfer(MAX_DAILY_SOLO_SPEND);
                
    mLastSpend[msg.sender] = currentTime;
                
    return true;
  }
  
   
  function spendtokens(ERC20Basic contractaddress, uint256 _to, uint256 _main, uint256 _fraction) public returns (bool valid)
  {
        require( _to != 0x0); 
        require(_main <= MAX_DAILY_TOKEN_COSIGN_SPEND); 
        require(_fraction< (WHOLE_ETHER/FRACTION_ETHER)); 
        
         
        sendsignature();
        
        uint256 currentTime = block.timestamp;
        uint256 valid1=0;
        uint256 valid2=0;
        
         
         
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE1] < COSIGN_MAX_TIME)
        {
            mAmount1 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid1=1;
        }
        
        if (block.timestamp - mSignatures[CONTRACT_SIGNATURE2] < COSIGN_MAX_TIME)
        {
            mAmount2 = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
            valid2=1;
        }
        
        if (valid1==1 && valid2==1)  
        {
             
            require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH); 
        
            if (mAmount1 == mAmount2)
            {
                uint256 valuetosend = _main*WHOLE_ETHER + _fraction*FRACTION_ETHER;
                 
                contractaddress.transfer(address(_to), valuetosend);
                
                 
                valid1=0;
                valid2=0;
                mAmount1=0;
                mAmount2=0;
                
                 
                endsigning();
                
                return true;
            }
        }
        
         
        return false;
  }
        

   
  function taketokendaily(ERC20Basic contractaddress, uint256 _to) public returns (bool valid)
  {
    require( _to != 0x0); 
    
     
    require((msg.sender == CONTRACT_SIGNATURE1 || msg.sender == CONTRACT_SIGNATURE2)); 
        
    uint256 currentTime = block.timestamp;
        
     
    require(currentTime - mLastSpend[msg.sender] > DAY_LENGTH); 
    
     
    contractaddress.transfer(address(_to), MAX_DAILY_TOKEN_SOLO_SPEND);
                
    mLastSpend[msg.sender] = currentTime;
                
    return true;
  }
    
  function endsigning() internal
  {
       
      mLastSpend[CONTRACT_SIGNATURE1]=block.timestamp;
      mLastSpend[CONTRACT_SIGNATURE2]=block.timestamp;
      mSignatures[CONTRACT_SIGNATURE1]=0;
      mSignatures[CONTRACT_SIGNATURE2]=0;
  }
  
  function () public payable 
    {
       
    }
    
}