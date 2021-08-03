// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
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
    uint256 standardPrice = 0;
    uint256 tick = 0;
    uint256 lastTriggerBlock = block.number;
    uint256 matchAmount = 0;
    uint256 trigger = 0;
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
    // event sTest(string s);
    // event iTest(uint256 i);
    // event aTest(address a);

    event SellOrderPlaced(
        address asker,
        uint256 amount,
        uint256 price,
        string timestamp,
        uint256 tick
    );
    event BuyOrderPlaced(
        address bidder,
        uint256 amount,
        uint256 price,
        string timestamp,
        uint256 tick
    );
    event StandardPrice(uint256 standardPrice, string timestamp, uint256 tick);
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

    // Mappings
    // Every placed sell or buy is connected to the senders address 
    // and the addresses are stored in asks and buys
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

    //  Throws if buy does not include sufficient amount of ether
    modifier hasethBalance(uint256 _amount, uint256 _price) {
        require(
            (msg.value + remainingLockedValue[msg.sender]) >=
                ((_price) * _amount) * (10**1),
            "Not enough ether"
        );
        _;
    }

    //  Throws if sell does not include sufficient amount of token
    modifier hasCredits(uint256 _amount) {
        require(
            (_credits.allowance(msg.sender, address(this)) +
                remainingLockedValue[msg.sender]) >= _amount,
            "Not enough credits"
        );
        _;
    }

    //  Throws if minimal amount of blocks in between to two auctions
    // has not been mined
    modifier isTrigger() {
        require(block.number >= lastTriggerBlock + trigger);
        _;
    }

    //  Creation of a sell order
    //  _amount of electricity,
    //  _price is the reservation price for Energy,
    function add_sell_order(uint256 _amount, uint256 _price)
        public
        hasCredits(_amount)
    {
        string memory _timestamp = uint2str(block.timestamp);
        Ask storage ask = asks[msg.sender];
        ask.asker = msg.sender;
        ask.amount = _amount;
        ask.price = _price;
        ask.timestamp = _timestamp;
        ask_ids.push(msg.sender);
        remainingLockedValue[ask.asker] = _amount;
        _credits.transferFrom(msg.sender, address(this), _amount);
        emit SellOrderPlaced(msg.sender, _amount, _price, _timestamp, tick);
    }

    //  Creation of a Buy order
    //  _amount of electricity,
    //  _price is the reservation price for Energy,
    function add_buy_order(uint256 _amount, uint256 _price)
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
            if ((_price * 10**4 * _amount) < remainingLockedValue[msg.sender]) {
                payable(msg.sender).transfer(
                    remainingLockedValue[msg.sender] -
                        (_price * 10**1 * _amount)
                );
                remainingLockedValue[msg.sender] = (_price * 10**4 * _amount);
            } else {
                remainingLockedValue[msg.sender] = (remainingLockedValue[
                    msg.sender
                ] + msg.value);
            }
        }
        emit BuyOrderPlaced(msg.sender, _amount, _price, _timestamp, tick);
    }

    //  View functions
    //  Shows all current buys
    //  array containing all buys
    function getAllBuyOrders() public view returns (address[] memory) {
        return bid_ids;
    }

    // Shows price of buy
    // address of buyer
    // uint being his price in Cents*100
    function getBuyPrice(address _address) public view returns (uint256) {
        return bids[_address].price;
    }

    //  Shows electricity amount of buy
    //  address of buyer
    //  uint being the amount of electricity he wants to buy in kWh
    function getBuyAmount(address _address) public view returns (uint256) {
        return bids[_address].amount;
    }

    //  Shows point in time of bid
    //  address of bidder
    //  string reprensenting the timestamp of the bid
    function getBuyTimestamp(address _address)
        public
        view
        returns (string memory)
    {
        return bids[_address].timestamp;
    }

    //  Shows all current sales
    //  array containing all sales
    function getAllSellOrders() public view returns (address[] memory) {
        return ask_ids;
    }

    //  Shows preferred price of sale
    //  address of asker
    //  uint being the price preference in Cents*100
    function getSellPrice(address _address) public view returns (uint256) {
        return asks[_address].price;
    }

    // Shows electricity amount of sale
    // address of seller
    // uint being the amount of electricity he wants to sell in kWh
    function getSellAmount(address _address) public view returns (uint256) {
        return asks[_address].amount;
    }

    // Shows point in time of ask
    // address of seller
    // string reprensenting the timestamp of the bid
    function getSellTimestamp(address _address)
        public
        view
        returns (string memory)
    {
        return asks[_address].timestamp;
    }

    // Shows the remaining locked value
    // address of buyer
    // uint being the amount of electricity (seller) or the
    // amount of ether that has been locked for the trading period
    function getRemainingValue(address _sender) public view returns (uint256) {
        return remainingLockedValue[_sender];
    }

    //  Shows all matches of trading period
    //  array containing all match-IDs
    function getMatches() public view returns (uint256[] memory) {
        return match_ids;
    }

    //  uint being the standardPrice in cent*100
    function getUniformprice() public view returns (uint256) {
        return standardPrice;
    }

    //  Function to check for bids and asks whether the auction should also be triggered
    function getBoolean() public view returns (bool value) {
        if (block.number >= lastTriggerBlock + trigger) {
            return true;
        }
    }

    //  Function to convert integer to string for timestamp
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

    //Sorts buys from highest to lowest
    function sort_array() private {
        uint256 l = bid_ids.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (getBuyPrice(bid_ids[i]) > getBuyPrice(bid_ids[j])) {
                    address temp = bid_ids[i];
                    bid_ids[i] = bid_ids[j];
                    bid_ids[j] = temp;
                }
            }
        }
    }

    function start_auction() public isTrigger {
        //Triggering the sorting of bids and asks, as well as triggering the auction
        lastTriggerBlock = block.number; //if the auction is triggered, then we save the current block
        reset_before();

        sort_array();
        pricematch();

        //rest_of_auction();
        matchingTransactions();
        reset_after();
    }

    //Pricematching
    function pricematch() private {
        for (uint256 i = 0; i < bid_ids.length; i++) {
            //go through all bids
            for (uint256 j = 0; j < ask_ids.length; j++) {
                //go through all the asks
                if (getSellAmount(ask_ids[j]) > 0) {
                    if (getBuyPrice(bid_ids[i]) <= getSellPrice(ask_ids[j])) {
                        //Offer price less than or equal to demand price
                        if (
                            getSellAmount(ask_ids[j]) <=
                            getBuyAmount(bid_ids[i])
                        ) {
                            //Demand quantity less than or equal to supply quantity
                            matchAmount = getSellAmount(ask_ids[j]); //then the demand quantity is the matched quantity
                        } else {
                            matchAmount = getBuyAmount(bid_ids[i]); //otherwise the demand will be partially filled with the remaining supply
                        }
                        if (matchAmount > 0) {
                            //if matchamount> 0, a match is created
                            Match storage _match = matches[match_id];
                            _match.bidaddress = bid_ids[i];
                            _match.askaddress = ask_ids[j];
                            _match.amount = matchAmount;
                            _match.timestamp = getBuyTimestamp(bid_ids[i]);
                            asks[ask_ids[j]].amount =
                                //Subtract matchAmount from Ask Amount
                                getSellAmount(ask_ids[j]) -
                                matchAmount;
                            bids[bid_ids[i]].amount =
                                //Subtract matchAmount from Bid Amount
                                getBuyAmount(bid_ids[i]) -
                                matchAmount;
                            match_ids.push(match_id);
                            match_id++;

                            emit MatchMade(
                                bid_ids[i],
                                ask_ids[j],
                                matchAmount,
                                getBuyTimestamp(bid_ids[i]),
                                tick
                            );
                        }
                    }
                }
            }
        }
    }

    //Transactions
    function matchingTransactions() private {
        for (uint256 z = 0; z < match_ids.length; z++) {
            _credits.transfer(
                matches[match_ids[z]].askaddress,
                (matches[match_ids[z]].amount)
            ); // Seller gets token from the contract (which we got from the buyer)
            payable(matches[match_ids[z]].bidaddress).transfer(
                matches[match_ids[z]].amount * getUniformprice() * (10**14)
            ); //Buyer gets eth from the contract (which we got from the seller)
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
        standardPrice = 0;
    }
}
