//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {
    struct Game {
        address firstPlayer;
        string firstPlayerChoice;
        address secoundPlayer;
        string secoundPlayerChoice;
        bool isDraw;
        address winner;
        bool exists;
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

    modifier validChoice(uint256 choiceId) {
        require(choiceId < options.length, "Invalid choice Id !");
        _;
    }

    modifier gameExists(address gameId) {
        require(games[gameId].exists, "Invalid gameId !");
        _;
    }

    constructor() {
        owner = msg.sender;
        options = ["R", "P", "S"];
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

    function createGame(uint256 choiceId)
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
        returns (Game memory)
    {
        require(games[gameId].isFinished == false, "This game has finished !");
        require(
            msg.sender != games[gameId].firstPlayer,
            "You've already played your role !"
        );

        games[gameId].secoundPlayer = msg.sender;
        games[gameId].secoundPlayerChoice = options[choiceId];
        games[gameId].isFinished = true;

        return games[gameId];
    }

    function findWinner(address gameId)
        external
        gameExists(gameId)
        returns (address)
    {
        // R , P , S

        require(
            games[gameId].isFinished == true,
            "The second player hasn't played yet !"
        );

        if (
            compareStringsbyBytes(
                games[gameId].firstPlayerChoice,
                games[gameId].secoundPlayerChoice
            )
        ) games[gameId].isDraw = true;
        else if (
            compareStringsbyBytes(games[gameId].firstPlayerChoice, options[0])
        ) {
            if (
                compareStringsbyBytes(
                    games[gameId].secoundPlayerChoice,
                    options[1]
                )
            ) games[gameId].winner = games[gameId].secoundPlayer;
            else games[gameId].winner = games[gameId].firstPlayer;
        } else if (
            compareStringsbyBytes(games[gameId].firstPlayerChoice, options[1])
        ) {
            if (
                compareStringsbyBytes(
                    games[gameId].secoundPlayerChoice,
                    options[2]
                )
            ) games[gameId].winner = games[gameId].secoundPlayer;
            else games[gameId].winner = games[gameId].firstPlayer;
        } else if (
            compareStringsbyBytes(games[gameId].firstPlayerChoice, options[2])
        ) {
            if (
                compareStringsbyBytes(
                    games[gameId].secoundPlayerChoice,
                    options[0]
                )
            ) games[gameId].winner = games[gameId].secoundPlayer;
            else games[gameId].winner = games[gameId].firstPlayer;
        }

        return games[gameId].winner;
    }

    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
