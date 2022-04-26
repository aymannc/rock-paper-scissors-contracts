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
        bool exists;
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

    modifier validChoice(uint256 choiceId) {
        require(choiceId < options.length, "Invalid choice Id !");
        _;
    }

    modifier gameExists(address gameId) {
        require(games[gameId].exists, "Invalid gameId !");
        _;
    }

    modifier gameFinished(address gameId) {
        require(games[gameId].isFinished == false, "This game has finished !");
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

    function initGame(uint256 choiceId)
        external
        validChoice(choiceId)
        returns (address)
    {
        Game memory game;
        game.firstPlayer = msg.sender;
        game.firstPlayerChoice = options[choiceId];
        game.exists = true;

        games[msg.sender] = game;
        console.log(msg.sender);

        return msg.sender;
    }

    function play(address gameId, uint256 choiceId)
        external
        validChoice(choiceId)
        gameExists(gameId)
        gameFinished(gameId)
        returns (Game memory)
    {
        require(
            msg.sender != games[gameId].firstPlayer,
            "You've already played your role !"
        );

        games[gameId].secoundPlayer = msg.sender;
        games[gameId].secoundPlayerChoice = options[choiceId];
        games[gameId].isFinished = true;

        return games[gameId];
    }
}
