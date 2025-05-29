// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract FairFight {
    address public admin;

    enum Outcome { Pending, Player1Wins, Player2Wins, Draw }

    struct Battle {
        address player1;
        address player2;
        uint256 stake;
        Outcome outcome;
        bool active;
    }

    uint256 public battleId;
    mapping(uint256 => Battle) public battles;

    event BattleCreated(uint256 indexed id, address player1, address player2, uint256 stake);
    event BattleResolved(uint256 indexed id, Outcome outcome);
    event StakeWithdrawn(uint256 indexed id, address winner, uint256 amount);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function createBattle(address player2) external payable returns (uint256) {
        require(msg.value > 0, "Stake required");

        battles[battleId] = Battle({
            player1: msg.sender,
            player2: player2,
            stake: msg.value,
            outcome: Outcome.Pending,
            active: true
        });

        emit BattleCreated(battleId, msg.sender, player2, msg.value);
        return battleId++;
    }

    function resolveBattle(uint256 id, Outcome result) external onlyAdmin {
        require(battles[id].active, "Battle not active");
        require(result != Outcome.Pending, "Invalid result");

        battles[id].outcome = result;
        battles[id].active = false;

        emit BattleResolved(id, result);
    }

    function withdrawStake(uint256 id) external {
        Battle storage b = battles[id];
        require(!b.active, "Battle still active");
        uint256 total = b.stake * 2;

        if (b.outcome == Outcome.Draw) {
            require(msg.sender == b.player1 || msg.sender == b.player2, "Not participant");
            payable(msg.sender).transfer(b.stake);
        } else if (
            (b.outcome == Outcome.Player1Wins && msg.sender == b.player1) ||
            (b.outcome == Outcome.Player2Wins && msg.sender == b.player2)
        ) {
            payable(msg.sender).transfer(total);
            emit StakeWithdrawn(id, msg.sender, total);
        } else {
            revert("Not winner");
        }

        // Prevent re-entrancy and double withdrawal
        b.stake = 0;
    }
}
