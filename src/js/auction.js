var web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));
var bidder = web3.eth.accounts[0];
web3.eth.defaultAccount = bidder;
var auctionContract = web3.eth.contract("Here the contract’s ABI"); // ABI omitted to make the code concise

function bid() {
var mybid = document.getElementById('value').value;

auction.bid({
value: web3.toWei(mybid, "ether"), gas: 200000
}, function(error, result) { if (error) {
console.log("error is " + error); document.getElementById("biding_status").innerHTML = "Think to bidding higher";
} else {
document.getElementById("biding_status").innerHTML = "Successfull bid, transaction ID" + result;
}
});
}

function init() { auction.auction_end(function(error, result) {
document.getElementById("auction_end").innerHTML = result;
});
auction.highestBidder(function(error, result) { document.getElementById("HighestBidder").innerHTML = result;
});
auction.highestBid(function(error, result) {
var bidEther = web3.fromWei(result, 'ether'); document.getElementById("HighestBid").innerHTML = bidEther;
});
auction.STATE(function(error, result) { document.getElementById("STATE").innerHTML = result;
});
auction.Mycar(function(error, result) { document.getElementById("car_brand").innerHTML = result[0]; document.getElementById("registration_number").innerHTML =
result[1];
});
auction.bids(bidder, function(error, result) { var bidEther = web3.fromWei(result, 'ether');
document.getElementById("MyBid").innerHTML = bidEther; console.log(bidder);
});
}

var auction_owner = null; auction.get_owner(function(error, result) {
if (!error) {
auction_owner = result;
if (bidder != auction_owner) {
$("#auction_owner_operations").hide();
}
}
});

function cancel_auction() { auction.cancel_auction(function(error, result) {
console.log(result);
});
}

function Destruct_auction() { auction.destruct_auction(function(error, result) {
console.log(result);
});
}

var BidEvent = auction.BidEvent(); BidEvent.watch(function(error, result) {
if (!error) {
$("#eventslog").html(result.args.highestBidder + ' has bidden(' + result.args.highestBid + ' wei)');
} else {
console.log(error);
}
});

var CanceledEvent = auction.CanceledEvent(); CanceledEvent.watch(function(error, result) {
if (!error) {
$("#eventslog").html(result.args.message + ' at ' + result.args.time);
}
});

const filter = web3.eth.filter({ fromBlock: 0,
toBlock: 'latest', address: contractAddress,
topics: [web3.sha3('BidEvent(address,uint256)')] });

filter.get((error, result) => {
if (!error) console.log(result);
});