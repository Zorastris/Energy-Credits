pragma solidity >=0.8.1 <0.9.0;

// ----------------------------------------------------------------------------
// Energy Credits
// ERC20 Standard Token
// Represents electricity in kWh
//
// Symbol      : EC
// Name        : Energy Credits
// Total supply: 1,000,000.000
// Decimals    : 3
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
// library SafeMath {
//     function add(uint a, uint b) internal pure returns (uint c) {

//         c = a + b;
//         //require(c >= a, "add");
//         return c;
//     }
//     function sub(uint a, uint b) internal pure returns (uint c) {
//         //require(b <= a, "sub");
//         return c = a - b;
//     }
//     function mul(uint a, uint b) internal pure returns (uint c) {
//         c = a * b;
//       // require(a == 0 || c / a == b, "mul");
//         return c;
//     }
//     function div(uint a, uint b) internal pure returns (uint c) {
//         //require(b > 0 , "div");
//         c = a / b;
//         return c;
//     }
// }

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Burn(address indexed from, uint256 value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract EnergyCredits is IERC20, Owned {
    // using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event sTest(string s);
    event iTest(uint256 i);
    event aTest(address a);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        symbol = "EC";
        name = "Energy Credits";
        decimals = 0;
        _totalSupply = 1000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function setBalance(address tokenOwner, uint256 newBal)
        internal
        returns (bool success)
    {
        balances[tokenOwner] = newBal;
        return true;
    }

    // ------------------------------------------------------------------------
    // Internal transfer function with all requirements
    // ------------------------------------------------------------------------
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));
        // Check if the sender has enough
        require(balances[_from] >= _value);
        //Check for empty transfer
        require(_value > 0);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Check if sender is frozen
        require(!frozenAccount[_from]);
        // Check if reciever is frozen
        require(!frozenAccount[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] = balances[_from] + _value;
        // Add the same to the recipient
        balances[_to] = balances[_to] + _value;
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);

        emit Transfer(_from, _to, _value);
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // ------------------------------------------------------------------------
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        // require(tokens <= balances[from]);

        // require(tokens <= allowed[from][msg.sender]);
        emit iTest(balances[from]);
        emit iTest(tokens);

        // uint newBal1 = balanceOf(from) - tokens;
        // uint newBal2 = balanceOf(to) + tokens;

        // emit iTest(newBal1);
        // setBalance(from, newBal1);
        // setBalance(from, newBal2);

        balances[from] -= tokens;

        allowed[from][msg.sender] -= tokens;

        balances[to] += tokens;

        emit Transfer(owner, to, tokens);

        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Mints new tokens and puts them in target´s account
    // ------------------------------------------------------------------------
    function mintToken(address target, uint256 amount)
        public
        onlyOwner
        returns (bool success)
    {
        balances[target] = balances[target] + amount;
        _totalSupply = _totalSupply + amount;
        emit Transfer(address(0), owner, amount);
        emit Transfer(owner, target, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Burns tokens
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        _totalSupply = _totalSupply - _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Freezes certain account. Tokens cannot be moved anymore
    // ------------------------------------------------------------------------
    function freezeAccount(address target, bool freeze)
        public
        onlyOwner
        returns (bool success)
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return IERC20(tokenAddress).transfer(owner, tokens);
    }
}

// contract Ownable {
//   address private _owner;

//   event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

//   //  The Ownable constructor sets the original `owner` of the contract to the sender
//   // account.
//   constructor() {
//     _owner = msg.sender;
//     emit OwnershipTransferred(address(0), _owner);
//   }

//   // @return the address of the owner.
//   function owner() public view returns(address) {
//     return _owner;
//   }

//   //  Throws if called by any account other than the owner.
//   modifier onlyOwner() {
//     require(isOwner());
//     _;
//   }

//   // @return true if `msg.sender` is the owner of the contract.
//   function isOwner() public view returns(bool) {
//     return msg.sender == _owner;
//   }

//   //  Allows the current owner to relinquish control of the contract.
//   // @notice Renouncing to ownership will leave the contract without an owner.
//   // It will not be possible to call the functions with the `onlyOwner`
//   // modifier anymore.
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipTransferred(_owner, address(0));
//     _owner = address(0);
//   }

//   //  Allows the current owner to transfer control of the contract to a newOwner.
//   // @param newOwner The address to transfer ownership to.
//   function transferOwnership(address newOwner) public onlyOwner {
//     _transferOwnership(newOwner);
//   }

//   //  Transfers control of the contract to a newOwner.
//   // @param newOwner The address to transfer ownership to.
//   function _transferOwnership(address newOwner) internal {
//     require(newOwner != address(0));
//     emit OwnershipTransferred(_owner, newOwner);
//     _owner = newOwner;
//   }
//   }

contract EnergyMarket {
    // uint fallbackPriceHigh = 2367;  // 23,67 Cent
    // uint fallbackPriceLow = 1200;   //12,00 Cent
    uint256 match_id = 0;
    uint256 uniformprice = 0;
    uint256 uniformPriceBHKW = 0;
    uint256 tick = 0;
    uint256 lastTriggerBlock = block.number;
    uint256 matchAmount = 0;
    uint256 trigger = 0;
    address ckaddress = address(0); // <-- manually change the address to your token address

    IERC20 public credits;

    constructor() {
        credits = new EnergyCredits();
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
                ((_price) * _amount) * (10**14)
        );
        _;
    }

    //  Throws if Ask does not include sufficient amount of token
    modifier hastokenBalance(uint256 _amount) {
        require(
            (credits.allowance(msg.sender, address(this)) +
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

    function addAsk(uint256 _amount, uint256 _price) public {
        string memory _timestamp = uint2str(block.timestamp);
        Ask storage ask = asks[msg.sender];
        ask.asker = msg.sender;
        ask.amount = _amount;
        ask.price = _price;
        ask.timestamp = _timestamp;
        ask_ids.push(msg.sender);
        //Works until here
        credits.transferFrom(msg.sender, address(this), _amount);
        emit AskPlaced(msg.sender, _amount, _price, _timestamp, tick);
    }

    //  Creation of a Bid
    // @param _amount of electricity, _price is the reservation price for PV-Energy,
    // _pricebhkw is the reservation price for CHP-Energy, _timestamp of bid
    // @notice A market participant can place an bid if no future ask has been made in t
    // his trading period, empty asks are forbidden to be protected against DOS attacks
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
                (_price * 10**14 * _amount) < remainingLockedValue[msg.sender]
            ) {
                payable(msg.sender).transfer(
                    remainingLockedValue[msg.sender] -
                        (_price * 10**14 * _amount)
                );
                remainingLockedValue[msg.sender] = (_price * 10**14 * _amount);
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

    // //  Shows point in time of ask
    // // @param address of asker
    // // @return string reprensenting the timestamp of the bid
    function getAskTimestamp(address _address)
        public
        view
        returns (string memory)
    {
        return asks[_address].timestamp;
    }

    // //  Shows the remaining locked value
    // // @param address of bidder/bidder
    // // @return uint being the amount of electricity (asker) or the
    // // amount of ether that has been locked for the trading period
    function getremainingvalue(address _sender) public view returns (uint256) {
        return remainingLockedValue[_sender];
    }

    //  Shows all matches of trading period
    // @return array containing all match-IDs
    function getMatches() public view returns (uint256[] memory) {
        return match_ids;
    }

    //  Shows UniformPrice for PV of this trading period
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
                greyAsk.price = fallbackPriceLow;
                greyAsk.timestamp = getBidTimestamp(bid_ids[i]);
                remainingLockedValue[greyAsk.asker] = 0;
                emit AskPlaced(
                    address(this),
                    matchAmount,
                    fallbackPriceLow,
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
                greyBid.price = fallbackPriceHigh;
                greyBid.timestamp = getAskTimestamp(ask_ids[j]);
                remainingLockedValue[greyBid.bidder] = 0;
                emit BidPlaced(
                    address(this),
                    matchAmount,
                    fallbackPriceHigh,
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
            credits.transfer(
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
        uint256 value = credits.balanceOf(msg.sender);
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
