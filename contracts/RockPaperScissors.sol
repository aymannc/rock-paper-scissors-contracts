//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {
    struct Game {
        address firstPlayer;
        string firstPlayerChoice;
        address secoundPlayer;
        string secoundPlayerChoice;
        address winner;
        bool isFinished;
    }

    mapping(address => Game) public games;

    string[] public options;

    address owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner is allowed to do this operation"
        );
        _;
    }

    constructor(string[] memory _options) {
        owner = msg.sender;
        options = _options;
    }

    /**
     * Read only function to retrieve the options of the game.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function getOptions() external view returns (string[] memory) {
        return options;
    }

    function setOptions(string[] memory _options) external onlyOwner {
        options = _options;
    }

    function initGame(string calldata choice) external returns (address) {
        Game memory game;
        game.firstPlayer = msg.sender;
        game.firstPlayerChoice = choice;
        game.isFinished = false;

        games[msg.sender] = game;
        console.log(msg.sender);

        return msg.sender;
    }
}
