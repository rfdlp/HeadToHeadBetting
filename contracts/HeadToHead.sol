pragma solidity ^0.8.0;

contract HeadToHeadBetting {
    address payable public contractOwner;
    address payable public player1;
    address payable public player2;
    uint public bet1;
    uint public bet2;
    uint public pot;
    bool public gameActive;
    mapping(address => uint) public playerRounds;
    uint public weeklyPlayerCount;
    uint256 private raffleBatchNumber = 1;
    mapping(uint256 => mapping(uint256 => address payable)) public weeklyRafflePlayers;
    uint public contractBalance;
    uint public weeklyRaffleBalance;
    uint public totalRounds;

    constructor() {
        contractOwner = payable(msg.sender);
        gameActive = true;
    }

    function placeBet() public payable {
        require(gameActive, "Game is currently paused.");
        require(msg.value >= 0.01 ether, "Minimum bet is 0.01 ETH.");
        require(player1 == address(0), "Round already in progress.");
        player1 = payable(msg.sender);
        bet1 = msg.value;
    }

    function matchBet() public payable {
        require(gameActive, "Game is currently paused.");
        require(msg.value >= bet1, "Bet must match or exceed previous bet.");
        require(player1 != msg.sender, "You have already placed a bet.");
        require(player2 == address(0), "Round already in progress.");
        player2 = payable(msg.sender);
        bet2 = msg.value;
    }

    function finishRound() public {
        require(payable(msg.sender) == contractOwner, "Only contract owner can finish a round.");
        require(player1 != address(0) && player2 != address(0), "No round in progress.");
        pot = bet1 + bet2;
        totalRounds++;
        contractBalance += pot * 1 / 40;
        weeklyRaffleBalance += pot * 3 / 40;
        weeklyRafflePlayers[raffleBatchNumber][weeklyPlayerCount] = player1;
        weeklyPlayerCount++;
        weeklyRafflePlayers[raffleBatchNumber][weeklyPlayerCount] = player2;
        weeklyPlayerCount++;
        address payable payout1 = player1;
        address payable payout2 = player2;
        player1 = payable(address(0));
        player2 = payable(address(0));
        bet1 = 0;
        bet2 = 0;

        uint winner = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2;
        if (winner == 0) {
            (bool success, ) = payout1.call{value:(pot * 9 / 10)}("");
            require(success, "Transfer failed.");

            playerRounds[payout1]++;
        } else {
            (bool success, ) = payout2.call{value:(pot * 9 / 10)}("");
            require(success, "Transfer failed.");
            playerRounds[payout2]++;
        }
    }
    function pauseGame() public {
        require(msg.sender == contractOwner, "Only contract owner can pause the game.");
        gameActive = false;
    }

    function unpauseGame() public {
        require(msg.sender == contractOwner, "Only contract owner can unpause the game.");
        gameActive = true;
    }

    function raffle() public {
        require(msg.sender == contractOwner, "Only contract owner can run the raffle.");
        require(weeklyPlayerCount > 0, "No players in the raffle pool.");
        require(weeklyRaffleBalance > 0, "No funds in the raffle pool.");

        uint winnerIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % weeklyPlayerCount;
        address payable winner = payable(weeklyRafflePlayers[raffleBatchNumber][winnerIndex]);

        uint rafflePayout = weeklyRaffleBalance;
        weeklyRaffleBalance = 0;
        weeklyPlayerCount = 0;
        raffleBatchNumber++;

        (bool success, ) = winner.call{value:rafflePayout}("");
        require(success, "Transfer failed.");
    }

    function withdraw() public {
        require(msg.sender == contractOwner, "Only contract owner can withdraw funds.");
        require(contractBalance > 0, "There are no funds to withdraw.");

        contractOwner.transfer(contractBalance);
        contractBalance = 0;
    }

    function getRounds(address player) public view returns (uint) {
        return playerRounds[player];
    }

    function getTotalRounds() public view returns (uint) {
        return totalRounds;
    }

    function getRoundStep() public view returns (uint) {
        if(player1 == address(0)){
            return 0;
        }else if(player1 != address(0) && player2 == address(0)){
            return 1;
        }else if(player1 != address(0) && player2 != address(0)){
            return 2;
        }else{
            return 3;
        }
    }

    function getBetValue() public view returns (uint) {
        if(player1 == address(0)){
            return bet1;
        }else if(player1 != address(0) && player2 == address(0)){
            return bet1;
        }else if(player1 != address(0) && player2 != address(0)){
            return bet1 + bet2;
        }else {
            return totalRounds;
        }
    }
}