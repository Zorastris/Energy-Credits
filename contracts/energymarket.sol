pragma solidity >=0.8.1 <0.9.0;

//  allowing the market mechanism to use functions of the Energy Credits
interface EnergyCreditsInterface{
  function totalSupply() external returns (uint);
  function balanceOf(address tokenOwner) external returns (uint balance);
  function transfer(address to, uint tokens) external returns (bool success);
  function approve(address spender, uint tokens) external returns (bool success);
  function transferFrom(address from, address to, uint tokens) external returns (bool success);
  function allowance(address tokenOwner, address spender) external returns (uint remaining);
  }
// ----------------------------------------------------------------------------
// @title Ownable
//  The Ownable contract has an owner address, and provides basic authorization control
// functions, this simplifies the implementation of "user permissions".
// ----------------------------------------------------------------------------
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);


  //  The Ownable constructor sets the original `owner` of the contract to the sender
  // account.
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }


  // @return the address of the owner.
  function owner() public view returns(address) {
    return _owner;
  }


  //  Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(isOwner());
    _;
  }


  // @return true if `msg.sender` is the owner of the contract.
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }


  //  Allows the current owner to relinquish control of the contract.
  // @notice Renouncing to ownership will leave the contract without an owner.
  // It will not be possible to call the functions with the `onlyOwner`
  // modifier anymore.
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }


  //  Allows the current owner to transfer control of the contract to a newOwner.
  // @param newOwner The address to transfer ownership to.
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }


  //  Transfers control of the contract to a newOwner.
  // @param newOwner The address to transfer ownership to.
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  }

contract EnergyMarket is Ownable{
uint fallbackPriceHigh = 2367;  // 23,67 Cent
uint fallbackPriceLow = 1200;   //12,00 Cent
uint match_id=0;
uint uniformprice = 0;
uint uniformPriceBHKW = 0;
uint tick = 0;
uint8 pv  = 0;
uint8 bhkw = 0;
uint lastTriggerBlock = block.number;
uint matchAmount = 0;
uint trigger = 0;
address ckaddress = address(0); // <-- manually change the address to your token address


// Structs
struct Ask {
  address asker;
  uint amount;
  uint price;
  string timestamp;
  }

struct Bid {
  address bidder;
  uint amount;
  uint price;
  string timestamp;
  }

struct Match{
  address askaddress;
  address bidaddress;
  uint amount;
  string timestamp;
  }


// Events
event AskPlaced (address asker, uint amount, uint price, string timestamp, uint tick);
event BidPlaced (address bidder, uint amount, uint price, string timestamp, uint tick);
event UniformPrice (uint uniformprice, string timestamp, uint tick);
event MatchMade (address asker, address bidder, uint amount, string timestamp, uint tick);
event Transaction(address from, address to, string what, uint amount, uint tick);
event UpdatePrice(uint oldprice, uint newprice, string which);
event ChangeofToken(address oldtoken, address ckaddress);


// Mappings
// Every placed ask or bid is connected to the senders address and the addresses
// are stored in an array
mapping(address => Ask) asks;
address[] public ask_ids;

mapping(address => Bid) bids;
address[] public bid_ids;

//  Every match made is connected to an ID which is stored in an array
mapping(uint => Match) matches;
uint[] public match_ids;

//  Locked value of all market participants is connected to their address
mapping(address => uint) remainingLockedValue;

// Links KITEnergyTokenInterface to specific smart contract
EnergyCreditsInterface EnergyCredits = EnergyCreditsInterface(ckaddress);

//  Constructor of contract to equip the market place with ether
constructor() payable{}

// Equip market place with more ether
function sendEther() public payable returns (bool success){
  return true;
  }

//  Throws if Bid does not include sufficient amount of ether
modifier hasethBalance(uint _amount, uint _price, uint _pricebhkw){
    uint _price = _pricebhkw;
    if (_price > _pricebhkw){
      _price = _price;
    }
    if(fallbackPriceHigh>_price){
      require((msg.value + remainingLockedValue[msg.sender])>=((fallbackPriceHigh)*_amount)*(10**14));
    }
    else{
      require((msg.value + remainingLockedValue[msg.sender])>=((_price)*_amount)*(10**14));
      }
      _;
    }

//  Throws if Ask does not include sufficient amount of token
modifier hastokenBalance(uint _amount){
      require((EnergyCredits.allowance(msg.sender,address(this)) + remainingLockedValue[msg.sender])>=_amount);
  _;
  }

//  Throws if minimal amount of blocks in between to two auctions
// has not been mined
modifier isTrigger(){
  require(block.number>=lastTriggerBlock+trigger);
  _;
  }

//  Creation of an Ask
// @param _amount of electricity, _price which is asked for, _energytype that is sold,
// _timestamp of ask
// @notice A market participant can place an ask if no future bid has been made in
// this trading period, empty asks are forbidden to be protected against DOS attacks
function addAsk (uint _amount, uint _price, string memory _timestamp) public hastokenBalance(_amount){
  require(bids[msg.sender].amount==0);
  require(_amount > 0);
  if(asks[msg.sender].amount==0){
    Ask storage ask = asks[msg.sender];
    ask.asker = msg.sender;
    ask.amount = _amount;
    ask.price = _price;
    ask.timestamp = _timestamp;
    ask_ids.push(msg.sender);
    remainingLockedValue[ask.asker]=_amount;
    EnergyCredits.transferFrom(msg.sender,address(this),_amount);
  }
  else {
    Ask storage askUpdate = asks[msg.sender];
    askUpdate.amount = _amount;
    askUpdate.price = _price;
    askUpdate.timestamp = _timestamp;
    asks[msg.sender] = askUpdate;

    if (_amount > remainingLockedValue[msg.sender]){
      EnergyCredits.transferFrom(msg.sender,address(this),(_amount-remainingLockedValue[msg.sender]));
    }
    else{
      EnergyCredits.transfer(msg.sender,(remainingLockedValue[msg.sender]-_amount));
    }
    remainingLockedValue[msg.sender]=_amount;
    }
    emit AskPlaced(msg.sender, _amount, _price,_timestamp,tick);
  }

//  Creation of a Bid
// @param _amount of electricity, _price is the reservation price for PV-Energy,
// _pricebhkw is the reservation price for CHP-Energy, _timestamp of bid
// @notice A market participant can place an bid if no future ask has been made in t
// his trading period, empty asks are forbidden to be protected against DOS attacks
function addBid (uint _amount, uint _price, uint _pricebhkw, string memory _timestamp) public payable hasethBalance(_amount,_price,_pricebhkw) {
    require(asks[msg.sender].amount==0);
    if(bids[msg.sender].amount==0){
      Bid storage bid = bids[msg.sender];
      bid.bidder = msg.sender;
      bid.amount = _amount;
      bid.price = _price;
      bid.timestamp = _timestamp;
      if (_pricebhkw > _price){
        bhkw++;
      }
      if (_price > _pricebhkw){
        pv++;
      }
      bid_ids.push(msg.sender);
      remainingLockedValue[msg.sender]=(msg.value);
    }
    else {
      Bid storage bidUpdate= bids[msg.sender];
      bidUpdate.amount = _amount;
      bidUpdate.price = _price;
      bidUpdate.timestamp = _timestamp;
      if (_pricebhkw > _price){
        bhkw++;
        pv--;
      }
      if(_pricebhkw < _price){
        pv++;
        bhkw--;
      }

      bids[msg.sender] = bidUpdate;

      uint _price = _pricebhkw;
      if (_price > _pricebhkw){
        _price = _price;
      }
      if(fallbackPriceHigh>_price){
        _price = fallbackPriceHigh;
      }

      if ((_price * 10**14 * _amount) < remainingLockedValue[msg.sender]){
        payable(msg.sender).transfer(remainingLockedValue[msg.sender] - (_price * 10**14 * _amount));
        remainingLockedValue[msg.sender]= (_price * 10**14 * _amount);
      }
      else{
        remainingLockedValue[msg.sender]=(remainingLockedValue[msg.sender]+msg.value);
      }
    }
    emit BidPlaced (msg.sender, _amount, _price, _timestamp, tick);
  }

//Update Functions
function changeTokenAddress(address _token) public onlyOwner returns (bool){
  address oldtoken = ckaddress;
  ckaddress = _token;
  emit ChangeofToken(oldtoken,ckaddress);
  return true;
}

// View functions
//  Shows all current bids
// @return array containing all bids
function getAllBids() public view returns (address[] memory){
  return bid_ids;
  }

// //  Shows PV-price of bid
// // @param address of bidder
// // @return uint being his PV-price in Cents*100
function getBidPrice(address _address) public view returns (uint){
  return bids[_address].price;
  }

// //  Shows electricity amount of bid
// // @param address of bidder
// // @return uint being the amount of electricity he wants to buy in kWh
function getBidAmount(address _address) public view returns (uint){
  return bids[_address].amount;
  } 

// //  Shows point in time of bid
// // @param address of bidder
// // @return string reprensenting the timestamp of the bid
function getBidTimestamp(address _address) public view returns (string memory){
  return bids[_address].timestamp;
}

//  Shows all current asks
// @return array containing all asks
function getAllAsks() public view returns (address[] memory){
      return ask_ids;
    }

// //  Shows preferred price of ask
// // @param address of asker
// // @return uint being the price preference in Cents*100
function getAskPrice(address _address) public view returns (uint){
  return asks[_address].price;
  }

// //  Shows electricity amount of ask
// // @param address of asker
// // @return uint being the amount of electricity he wants to sell in kWh
function getAskAmount(address _address) public view returns (uint){
  return asks[_address].amount;
  }


// //  Shows point in time of ask
// // @param address of asker
// // @return string reprensenting the timestamp of the bid
function getAskTimestamp(address _address) public view returns (string memory){
  return asks[_address].timestamp;
}

// //  Shows the remaining locked value
// // @param address of bidder/bidder
// // @return uint being the amount of electricity (asker) or the
// // amount of ether that has been locked for the trading period
function getremainingvalue (address _sender) public view returns(uint){
  return remainingLockedValue[_sender];
  }

//  Shows the fallbackprice for buyers
// @return the current fallbackprichigh in cent*100
function getfallbackPriceHigh() public view returns(uint){
  return fallbackPriceHigh;
  }

//  Shows the fallbackprice for sellers
// @return the current fallbackpricelow in cent*100
function getfallbackPriceLow() public view returns(uint){
  return fallbackPriceLow;
  }

//  Shows all matches of trading period
// @return array containing all match-IDs
function getMatches() public view returns (uint[] memory){
  return match_ids;
  }

//  Shows UniformPrice for PV of this trading period
// @return uint being the uniformprice in cent*100
function getUniformprice () public view returns (uint) {
  return uniformprice;
  }

//function um bei Bids und Asks zu prüfen, ob auch die Auction getriggered werden soll
function getBoolean() public view returns(bool){
    if(block.number>=lastTriggerBlock+trigger){
        return true;
    }
  }

function updateFallbackPriceHigh(uint _fallbackpricehigh) public onlyOwner returns (bool){ //reihenfolge checken und owner implementieren
    uint r = fallbackPriceHigh;
    fallbackPriceHigh = _fallbackpricehigh;
    emit UpdatePrice(r,fallbackPriceHigh,"fallbackpricehigh");
    return true;
  }

function updateFallbackPriceLow(uint _fallbackpricelow) public onlyOwner returns (bool) { //reihenfolge checken und owner implementieren
    uint r = fallbackPriceLow;
    fallbackPriceLow = _fallbackpricelow;
    emit UpdatePrice(r,fallbackPriceLow,"fallbackpricelow");
    return true;
  }

//Adjustment of the distance between two auctions
function setTrigger(uint t) public onlyOwner returns(bool) {
  trigger = t;
  return true;
  }


//  Sorting array of asks upwards
function sort_array() private{
    uint256 l = bid_ids.length;
    for(uint i = 0; i < l; i++) {
        for(uint j = i+1; j < l ;j++) {
            if(getBidPrice(bid_ids[i]) > getBidPrice(bid_ids[j])) {
                address temp = bid_ids[i];
                bid_ids[i] = bid_ids[j];
                bid_ids[j] = temp;
            }
        }
    }
  }

function try_to_auction() public isTrigger{
  //Triggering the sorting of bids and asks, as well as triggering the auction
  lastTriggerBlock=block.number;  //if the auction is triggered, then we save the current block
  reset_before();
  if(bhkw > pv){
    sort_array(); // with function then call is trigger? But then the part here is executed every time. not like that!
    pvmatching();
    }
  else{
    sort_array();
    pvmatching();
    }
  rest_of_auction();
  //matchingTransactions();
  reset_after();
    }

//Matching in the PV market
function pvmatching() private{
  for (uint i=0; i<bid_ids.length; i++) { //go through all bids
      for(uint j = 0; j< ask_ids.length; j++){  //go through all the asks
          if(getAskAmount(ask_ids[j]) > 0){
          if(getBidPrice(bid_ids[i]) <= getAskPrice(ask_ids[j])){ //Offer price less than or equal to demand price
             if(getAskAmount(ask_ids[j]) <= getBidAmount(bid_ids[i])){  //Demand quantity less than or equal to supply quantity
                 matchAmount = getAskAmount(ask_ids[j]);  //then the demand quantity is the matched quantity
             }else{
                 matchAmount = getBidAmount(bid_ids[i]);  //otherwise the demand will be partially filled with the remaining supply
             }
             if(matchAmount > 0){ //if matchamount> 0 a match is created
                 Match storage _matchPV = matches[match_id];
                 _matchPV.bidaddress = bid_ids[i];
                 _matchPV.askaddress = ask_ids[j];
                 _matchPV.amount = matchAmount;
                 _matchPV.timestamp = getBidTimestamp(bid_ids[i]);
                 asks[ask_ids[j]].amount = getAskAmount(ask_ids[j]) - matchAmount; //matchAmount von Ask Amount abziehen
                 bids[bid_ids[i]].amount = getBidAmount(bid_ids[i]) - matchAmount; //matchAmount von Bid Amount abziehen
                 match_ids.push(match_id);
                 match_id++;

                 emit MatchMade(bid_ids[i],ask_ids[j],matchAmount,getBidTimestamp(bid_ids[i]),tick);
             }
          }
          }
      }
    }
  }

function rest_of_auction() private{
  //Matching in GreyMarket with the remaining offer quantities, Ask is provided here by GreyMarket
  for(uint i = 0; i < bid_ids.length; i++){
    if(getBidAmount(bid_ids[i]) > 0){
      matchAmount = getBidAmount(bid_ids[i]);
      Match storage matchGrey1 = matches[match_id];

      Ask storage greyAsk = asks[address(this)];
      greyAsk.asker = address(this);
      greyAsk.amount = matchAmount;
      greyAsk.price = fallbackPriceLow;
      greyAsk.timestamp = getBidTimestamp(bid_ids[i]);
      remainingLockedValue[greyAsk.asker] = 0;
      emit AskPlaced(address(this),matchAmount,fallbackPriceLow,getBidTimestamp(bid_ids[i]),tick);

      matchGrey1.bidaddress = bid_ids[i];
      matchGrey1.askaddress = address(this);
      matchGrey1.amount = matchAmount;
      matchGrey1.timestamp = getBidTimestamp(bid_ids[i]);
      match_ids.push(match_id);
      bids[bid_ids[i]].amount = getBidAmount(bid_ids[i]) - matchAmount;
      match_id++;

      emit MatchMade(bids[bid_ids[i]].bidder,greyAsk.asker,matchAmount,getBidTimestamp(bid_ids[i]),tick);
      }
    }

  //Matching in GreyMarket with the remaining demand, the bid is made here by GreyMarket
  for(uint j = 0; j < ask_ids.length; j++){
    if(getAskAmount(ask_ids[j]) > 0){
      matchAmount = getAskAmount(ask_ids[j]);
      Match storage matchGrey2 = matches[match_id];

      Bid storage greyBid = bids[address(this)];
      greyBid.bidder = address(this);
      greyBid.amount = matchAmount;
      greyBid.price = fallbackPriceHigh;
      greyBid.timestamp = getAskTimestamp(ask_ids[j]);
      remainingLockedValue[greyBid.bidder]=0;
      emit BidPlaced(address(this),matchAmount,fallbackPriceHigh,getAskTimestamp(ask_ids[j]),tick);

      matchGrey2.askaddress = ask_ids[j];
      matchGrey2.bidaddress = address(this);
      matchGrey2.amount = matchAmount;
      matchGrey2.timestamp = getAskTimestamp(ask_ids[j]);
      match_ids.push(match_id);
      asks[ask_ids[j]].amount = getAskAmount(ask_ids[j]) - matchAmount;
      match_id++;

      emit MatchMade(greyBid.bidder,asks[ask_ids[j]].asker,matchAmount,getAskTimestamp(ask_ids[j]),tick);

      }
    }
  }


//divide by 100 possibly omit so there is no type force


//Transactions
function matchingTransactions() private {
    //Transactions for PV
    for(uint z = 0; z < match_ids.length; z++){
        EnergyCredits.transfer(matches[match_ids[z]].askaddress,(matches[match_ids[z]].amount)); // Asker bekommt token vom contract (die wir vom Bidder bekommen haben)
        payable(matches[match_ids[z]].bidaddress).transfer(matches[match_ids[z]].amount*getUniformprice()*(10**14)); //Bidder bekommt eth vom contract (die wir vom Asker bekommen haben)
        remainingLockedValue[matches[match_ids[z]].askaddress] = remainingLockedValue[matches[match_ids[z]].askaddress] - (matches[match_ids[z]].amount * getUniformprice()* (10**14)); //remainingLockedValue wird um Transaktionsvolumen reduziert
        emit Transaction(matches[match_ids[z]].askaddress,matches[match_ids[z]].bidaddress,"Cent*100",matches[match_ids[z]].amount*getUniformprice(),tick);
        remainingLockedValue[matches[match_ids[z]].bidaddress] = remainingLockedValue[matches[match_ids[z]].bidaddress] - (matches[match_ids[z]].amount); //remainingLockedValue wird um Transaktionsvolumen reduziert
        emit Transaction(matches[match_ids[z]].bidaddress,matches[match_ids[z]].askaddress,"Token",matches[match_ids[z]].amount,tick);
      
    }

    //Transactions for Gray at GreyMarket as Ask
    // for(uint z = 0; z < match_ids.length; z++){
    //   if(getMatchPreference(z)==1){
    //     emit Transaction(matches[match_ids[z]].bidaddress,matches[match_ids[z]].askaddress,"Token",matches[match_ids[z]].amount,tick);
    //     matches[match_ids[z]].bidaddress.transfer(matches[match_ids[z]].amount*fallbackPriceLow*(10**14));
    //     remainingLockedValue[matches[match_ids[z]].bidaddress] = remainingLockedValue[matches[match_ids[z]].bidaddress] - (matches[match_ids[z]].amount);
    //     emit Transaction(matches[match_ids[z]].askaddress,matches[match_ids[z]].bidaddress,"Cent*100",matches[match_ids[z]].amount*fallbackPriceLow,tick);
    //   }
    // }

    // //Transactions for Gray at GreyMarket as a bid
    // for(uint z = 0; z < match_ids.length; z++){
    //   if(getMatchPreference(z)==4){
    //     energytoken.transfer(matches[match_ids[z]].askaddress,(matches[match_ids[z]].amount));
    //     remainingLockedValue[matches[match_ids[z]].askaddress] = remainingLockedValue[matches[match_ids[z]].askaddress] - (matches[match_ids[z]].amount*fallbackPriceHigh*(10**14));
    //     emit Transaction(matches[match_ids[z]].bidaddress,matches[match_ids[z]].askaddress,"Token",matches[match_ids[z]].amount,tick);
    //     emit Transaction(matches[match_ids[z]].askaddress,matches[match_ids[z]].bidaddress,"Cent*100",matches[match_ids[z]].amount*fallbackPriceHigh,tick);
    //   }
    // }
    


    //Refunds if the blocked amount is higher than the amount actually paid and the mappings & arrays are deleted
    for(uint z = 0; z < match_ids.length; z++){
         if(remainingLockedValue[matches[match_ids[z]].askaddress]>0){
           payable(matches[match_ids[z]].askaddress).transfer(remainingLockedValue[matches[match_ids[z]].askaddress]);
           emit Transaction(address(this),matches[match_ids[z]].askaddress,"Repayment Wei",remainingLockedValue[matches[match_ids[z]].askaddress],tick);
           remainingLockedValue[matches[match_ids[z]].askaddress] = 0;
         }
       }
    }

function reset_after() private {
    delete bid_ids;
    delete ask_ids;
    pv = 0;
    tick++;
  }

function reset_before() private{
    delete match_ids;
    match_id = 0;
    uniformprice = 0;

}

}
