// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnergyCredits is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Energy Credits", "EC") {
        _mint(msg.sender, 50000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract EnergyMarket {
    uint256 fallbackPrice = 8000;
    uint256 match_id = 0;
    uint256 uniformprice = 0;
    uint256 tick = 0;
    uint256 lastTriggerBlock = block.number;
    uint256 matchAmount = 0;
    uint256 trigger = 0;
    address ckaddress = address(0); // <-- manually change the address to your token address
    IERC20 private _credits;

    constructor(IERC20 credits) {
        _credits = credits;
    }

    // Structs
    struct Ask {
        address asker;
        uint256 amount;
        uint256 price;
        string timestamp;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 price;
        string timestamp;
    }

    struct Match {
        address askaddress;
        address bidaddress;
        uint256 amount;
        string timestamp;
    }

    // Events
    event sTest(string s);
    event iTest(uint256 i);
    event aTest(address a);
    event AskPlaced(
        address asker,
        uint256 amount,
        uint256 price,
        string timestamp,
        uint256 tick
    );
    event BidPlaced(
        address bidder,
        uint256 amount,
        uint256 price,
        string timestamp,
        uint256 tick
    );
    event UniformPrice(uint256 uniformprice, string timestamp, uint256 tick);
    event MatchMade(
        address asker,
        address bidder,
        uint256 amount,
        string timestamp,
        uint256 tick
    );
    event Transaction(
        address from,
        address to,
        string what,
        uint256 amount,
        uint256 tick
    );
    event UpdatePrice(uint256 oldprice, uint256 newprice, string which);
    event ChangeofToken(address oldtoken, address ckaddress);

    // Mappings
    // Every placed ask or bid is connected to the senders address and the addresses
    // are stored in an array
    mapping(address => Ask) asks;
    address[] public ask_ids;

    mapping(address => Bid) bids;
    address[] public bid_ids;

    //  Every match made is connected to an ID which is stored in an array
    mapping(uint256 => Match) matches;
    uint256[] public match_ids;

    //  Locked value of all market participants is connected to their address
    mapping(address => uint256) remainingLockedValue;

    // Equip market place with more ether
    function sendEther() public payable returns (bool success) {
        return true;
    }

    //  Throws if Bid does not include sufficient amount of ether
    modifier hasethBalance(uint256 _amount, uint256 _price) {
        require(
            (msg.value + remainingLockedValue[msg.sender]) >=
                ((_price) * _amount) * (10**1), "Not enough ether"
        );
        _;
    }

    //  Throws if Ask does not include sufficient amount of token
    modifier hastokenBalance(uint256 _amount) {
        require(
            (_credits.allowance(msg.sender, address(this)) +
                remainingLockedValue[msg.sender]) >= _amount
        );
        _;
    }

    //  Throws if minimal amount of blocks in between to two auctions
    // has not been mined
    modifier isTrigger() {
        require(block.number >= lastTriggerBlock + trigger);
        _;
    }

    function addAsk(uint256 _amount, uint256 _price)
        public
        hastokenBalance(_amount)
    {
        string memory _timestamp = uint2str(block.timestamp);
        Ask storage ask = asks[msg.sender];
        ask.asker = msg.sender;
        ask.amount = _amount;
        ask.price = _price;
        ask.timestamp = _timestamp;
        ask_ids.push(msg.sender);
        remainingLockedValue[ask.asker]=_amount;
        _credits.transferFrom(msg.sender, address(this), _amount);
        emit AskPlaced(msg.sender, _amount, _price, _timestamp, tick);
    }

    //  Creation of a Bid
    //  _amount of electricity, 
    //  _price is the reservation price for Energy,
    //  A market participant can place an bid if no future ask has been made  
    //  in this trading period
    function addBid(uint256 _amount, uint256 _price)
        public
        payable
        hasethBalance(_amount, _price)
    {
        string memory _timestamp = uint2str(block.timestamp);
        require(asks[msg.sender].amount == 0);
        if (bids[msg.sender].amount == 0) {
            Bid storage bid = bids[msg.sender];
            bid.bidder = msg.sender;
            bid.amount = _amount;
            bid.price = _price;
            bid.timestamp = _timestamp;
            bid_ids.push(msg.sender);
            remainingLockedValue[msg.sender] = (msg.value);
        } else {
            Bid storage bidUpdate = bids[msg.sender];
            bidUpdate.amount = _amount;
            bidUpdate.price = _price;
            bidUpdate.timestamp = _timestamp;
            bids[msg.sender] = bidUpdate;
            if (
                (_price * 10**1 * _amount) < remainingLockedValue[msg.sender]
            ) {
                payable(msg.sender).transfer(
                    remainingLockedValue[msg.sender] -
                        (_price * 10**4 * _amount)
                );
                remainingLockedValue[msg.sender] = (_price * 10**1 * _amount);
            } else {
                remainingLockedValue[msg.sender] = (remainingLockedValue[
                    msg.sender
                ] + msg.value);
            }
        }
        emit BidPlaced(msg.sender, _amount, _price, _timestamp, tick);
    }

    //Update Functions
    // function changeTokenAddress(address _token) public onlyOwner returns (bool){
    //   address oldtoken = ckaddress;
    //   ckaddress = _token;
    //   emit ChangeofToken(oldtoken,ckaddress);
    //   return true;
    // }

    // View functions
    //  Shows all current bids
    // @return array containing all bids
    function getAllBids() public view returns (address[] memory) {
        return bid_ids;
    }

    // // Shows price of bid
    // // address of bidder
    // // uint being his price in Cents*100
    function getBidPrice(address _address) public view returns (uint256) {
        return bids[_address].price;
    }

    // //  Shows electricity amount of bid
    // //  address of bidder
    // //  uint being the amount of electricity he wants to buy in kWh
    function getBidAmount(address _address) public view returns (uint256) {
        return bids[_address].amount;
    }

    // //  Shows point in time of bid
    // //  address of bidder
    // //  string reprensenting the timestamp of the bid
    function getBidTimestamp(address _address)
        public
        view
        returns (string memory)
    {
        return bids[_address].timestamp;
    }

    //  Shows all current asks
    // @return array containing all asks
    function getAllAsks() public view returns (address[] memory) {
        return ask_ids;
    }

    // //  Shows preferred price of ask
    // // @param address of asker
    // // @return uint being the price preference in Cents*100
    function getAskPrice(address _address) public view returns (uint256) {
        return asks[_address].price;
    }

    // //  Shows electricity amount of ask
    // // @param address of asker
    // // @return uint being the amount of electricity he wants to sell in kWh
    function getAskAmount(address _address) public view returns (uint256) {
        return asks[_address].amount;
    }

    // Shows point in time of ask
    // address of asker
    // string reprensenting the timestamp of the bid
    function getAskTimestamp(address _address)
        public
        view
        returns (string memory)
    {
        return asks[_address].timestamp;
    }

    // Shows the remaining locked value
    // address of bidder/bidder
    // uint being the amount of electricity (asker) or the
    // amount of ether that has been locked for the trading period
    function getremainingvalue(address _sender) public view returns (uint256) {
        return remainingLockedValue[_sender];
    }

    //  Shows all matches of trading period
    //  array containing all match-IDs
    function getMatches() public view returns (uint256[] memory) {
        return match_ids;
    }

    //  uint being the uniformprice in cent*100
    function getUniformprice() public view returns (uint256) {
        return uniformprice;
    }

    // Function to check for bids and asks whether the auction should also be triggered
    function getBoolean() public view returns (bool value) {
        if (block.number >= lastTriggerBlock + trigger) {
            return true;
        }
    }

    //function to convert integer  to string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

    //  Sorting array of asks upwards
    function sort_array() private {
        uint256 l = bid_ids.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (getBidPrice(bid_ids[i]) > getBidPrice(bid_ids[j])) {
                    address temp = bid_ids[i];
                    bid_ids[i] = bid_ids[j];
                    bid_ids[j] = temp;
                }
            }
        }
    }

    function try_to_auction() public isTrigger {
        //Triggering the sorting of bids and asks, as well as triggering the auction
        lastTriggerBlock = block.number; //if the auction is triggered, then we save the current block
        reset_before();

        sort_array();
        pvmatching();

        rest_of_auction();
        //matchingTransactions();
        reset_after();
    }

    //Matching in the PV market
    function pvmatching() private {
        for (uint256 i = 0; i < bid_ids.length; i++) {
            //go through all bids
            for (uint256 j = 0; j < ask_ids.length; j++) {
                //go through all the asks
                if (getAskAmount(ask_ids[j]) > 0) {
                    if (getBidPrice(bid_ids[i]) <= getAskPrice(ask_ids[j])) {
                        //Offer price less than or equal to demand price
                        if (
                            getAskAmount(ask_ids[j]) <= getBidAmount(bid_ids[i])
                        ) {
                            //Demand quantity less than or equal to supply quantity
                            matchAmount = getAskAmount(ask_ids[j]); //then the demand quantity is the matched quantity
                        } else {
                            matchAmount = getBidAmount(bid_ids[i]); //otherwise the demand will be partially filled with the remaining supply
                        }
                        if (matchAmount > 0) {
                            //if matchamount> 0 a match is created
                            Match storage _matchPV = matches[match_id];
                            _matchPV.bidaddress = bid_ids[i];
                            _matchPV.askaddress = ask_ids[j];
                            _matchPV.amount = matchAmount;
                            _matchPV.timestamp = getBidTimestamp(bid_ids[i]);
                            asks[ask_ids[j]].amount =
                                getAskAmount(ask_ids[j]) -
                                matchAmount; //matchAmount von Ask Amount abziehen
                            bids[bid_ids[i]].amount =
                                getBidAmount(bid_ids[i]) -
                                matchAmount; //matchAmount von Bid Amount abziehen
                            match_ids.push(match_id);
                            match_id++;

                            emit MatchMade(
                                bid_ids[i],
                                ask_ids[j],
                                matchAmount,
                                getBidTimestamp(bid_ids[i]),
                                tick
                            );
                        }
                    }
                }
            }
        }
    }

    function rest_of_auction() private {
        //Matching in GreyMarket with the remaining offer quantities, Ask is provided here by GreyMarket
        for (uint256 i = 0; i < bid_ids.length; i++) {
            if (getBidAmount(bid_ids[i]) > 0) {
                matchAmount = getBidAmount(bid_ids[i]);
                Match storage matchGrey1 = matches[match_id];

                Ask storage greyAsk = asks[address(this)];
                greyAsk.asker = address(this);
                greyAsk.amount = matchAmount;
                greyAsk.price = fallbackPrice;
                greyAsk.timestamp = getBidTimestamp(bid_ids[i]);
                remainingLockedValue[greyAsk.asker] = 0;
                emit AskPlaced(
                    address(this),
                    matchAmount,
                    fallbackPrice,
                    getBidTimestamp(bid_ids[i]),
                    tick
                );

                matchGrey1.bidaddress = bid_ids[i];
                matchGrey1.askaddress = address(this);
                matchGrey1.amount = matchAmount;
                matchGrey1.timestamp = getBidTimestamp(bid_ids[i]);
                match_ids.push(match_id);
                bids[bid_ids[i]].amount =
                    getBidAmount(bid_ids[i]) -
                    matchAmount;
                match_id++;

                emit MatchMade(
                    bids[bid_ids[i]].bidder,
                    greyAsk.asker,
                    matchAmount,
                    getBidTimestamp(bid_ids[i]),
                    tick
                );
            }
        }

        //Matching in GreyMarket with the remaining demand, the bid is made here by GreyMarket
        for (uint256 j = 0; j < ask_ids.length; j++) {
            if (getAskAmount(ask_ids[j]) > 0) {
                matchAmount = getAskAmount(ask_ids[j]);
                Match storage matchGrey2 = matches[match_id];

                Bid storage greyBid = bids[address(this)];
                greyBid.bidder = address(this);
                greyBid.amount = matchAmount;
                greyBid.price = fallbackPrice;
                greyBid.timestamp = getAskTimestamp(ask_ids[j]);
                remainingLockedValue[greyBid.bidder] = 0;
                emit BidPlaced(
                    address(this),
                    matchAmount,
                    fallbackPrice,
                    getAskTimestamp(ask_ids[j]),
                    tick
                );

                matchGrey2.askaddress = ask_ids[j];
                matchGrey2.bidaddress = address(this);
                matchGrey2.amount = matchAmount;
                matchGrey2.timestamp = getAskTimestamp(ask_ids[j]);
                match_ids.push(match_id);
                asks[ask_ids[j]].amount =
                    getAskAmount(ask_ids[j]) -
                    matchAmount;
                match_id++;

                emit MatchMade(
                    greyBid.bidder,
                    asks[ask_ids[j]].asker,
                    matchAmount,
                    getAskTimestamp(ask_ids[j]),
                    tick
                );
            }
        }
    }

    //divide by 100 possibly omit so there is no type force

    //Transactions
    function matchingTransactions() private {
        //Transactions for PV
        for (uint256 z = 0; z < match_ids.length; z++) {
            _credits.transfer(
                matches[match_ids[z]].askaddress,
                (matches[match_ids[z]].amount)
            ); // Asker bekommt token vom contract (die wir vom Bidder bekommen haben)
            payable(matches[match_ids[z]].bidaddress).transfer(
                matches[match_ids[z]].amount * getUniformprice() * (10**14)
            ); //Bidder bekommt eth vom contract (die wir vom Asker bekommen haben)
            remainingLockedValue[matches[match_ids[z]].askaddress] =
                remainingLockedValue[matches[match_ids[z]].askaddress] -
                (matches[match_ids[z]].amount * getUniformprice() * (10**14)); //remainingLockedValue wird um Transaktionsvolumen reduziert
            emit Transaction(
                matches[match_ids[z]].askaddress,
                matches[match_ids[z]].bidaddress,
                "Cent*100",
                matches[match_ids[z]].amount * getUniformprice(),
                tick
            );
            remainingLockedValue[matches[match_ids[z]].bidaddress] =
                remainingLockedValue[matches[match_ids[z]].bidaddress] -
                (matches[match_ids[z]].amount); //remainingLockedValue wird um Transaktionsvolumen reduziert
            emit Transaction(
                matches[match_ids[z]].bidaddress,
                matches[match_ids[z]].askaddress,
                "Token",
                matches[match_ids[z]].amount,
                tick
            );
        }

        //Refunds if the blocked amount is higher than the amount actually paid and the mappings & arrays are deleted
        for (uint256 z = 0; z < match_ids.length; z++) {
            if (remainingLockedValue[matches[match_ids[z]].askaddress] > 0) {
                payable(matches[match_ids[z]].askaddress).transfer(
                    remainingLockedValue[matches[match_ids[z]].askaddress]
                );
                emit Transaction(
                    address(this),
                    matches[match_ids[z]].askaddress,
                    "Repayment Wei",
                    remainingLockedValue[matches[match_ids[z]].askaddress],
                    tick
                );
                remainingLockedValue[matches[match_ids[z]].askaddress] = 0;
            }
        }
    }

    function reset_after() private {
        delete bid_ids;
        delete ask_ids;
        tick++;
    }

    function reset_before() private {
        delete match_ids;
        match_id = 0;
        uniformprice = 0;
    }

    function test() public returns (uint256) {
        uint256 value = _credits.balanceOf(msg.sender);
        emit iTest(value);
        return value;
    }

    function testA() public returns (address) {
        emit aTest(address(this));
        return address(this);
    }

    function testB() public returns (address) {
        emit aTest(address(msg.sender));
        return address(msg.sender);
    }
}
