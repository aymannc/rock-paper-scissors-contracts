//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {
    enum Choice {
        UNDEFINED,
        ROCK,
        PAPER,
        SCISSORS
    }

    struct Player {
        address playerAddress;
        Choice choice;
        bytes32 hashedChoice;
        uint256 nonce;
    }

    struct Game {
        Player firstPlayer;
        Player secondPlayer;
        address winner;
        uint256 timestamp;
        bool isFinished;
        bool isDraw;
    }

    mapping(address => Game) public games;

    address owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner is allowed to do this operation"
        );
        _;
    }

    modifier validChoice(Choice _choice) {
        require(
            _choice >= Choice.ROCK && _choice <= Choice.SCISSORS,
            "Invalid choice !"
        );
        _;
    }

    modifier gameExists(address _gameId) {
        require(games[_gameId].timestamp > 0, "Invalid _gameId !");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createGame(Choice _choice, uint256 _nonce)
        external
        validChoice(_choice)
        returns (address)
    {
        require(
            games[msg.sender].timestamp == 0 || games[msg.sender].isFinished,
            "You can't create a new game until the old one finishes !"
        );

        Game memory game;
        game.firstPlayer.playerAddress = msg.sender;
        game.firstPlayer.hashedChoice = keccak256(
            abi.encodePacked(_choice, _nonce)
        );
        game.timestamp = block.timestamp;

        games[msg.sender] = game;

        console.log(msg.sender);

        return msg.sender;
    }

    function submit(
        address _gameId,
        Choice _choice,
        uint256 _nonce
    ) external validChoice(_choice) gameExists(_gameId) {
        require(games[_gameId].isFinished == false, "This game has finished !");
        require(
            msg.sender != games[_gameId].firstPlayer.playerAddress,
            "You've already played your role !"
        );

        games[_gameId].secondPlayer.playerAddress = msg.sender;
        games[_gameId].secondPlayer.hashedChoice = keccak256(
            abi.encodePacked(_choice, _nonce)
        );
    }

    function reveal(
        address _gameId,
        Choice _choice,
        uint256 _nonce
    ) external validChoice(_choice) gameExists(_gameId) returns (address) {
        require(games[_gameId].isFinished == false, "This game has finished !");

        require(
            games[_gameId].firstPlayer.playerAddress == msg.sender ||
                games[_gameId].secondPlayer.playerAddress == msg.sender,
            "You don't have access into this game !"
        );

        require(
            games[_gameId].secondPlayer.hashedChoice != 0,
            "Can't reveal choices yet, all players need to submit choices !"
        );

        require(
            (games[_gameId].firstPlayer.playerAddress == msg.sender &&
                games[_gameId].firstPlayer.choice == Choice.UNDEFINED) ||
                (games[_gameId].secondPlayer.playerAddress == msg.sender &&
                    games[_gameId].secondPlayer.choice == Choice.UNDEFINED),
            "You've already revealed your choice !"
        );

        if (games[_gameId].firstPlayer.playerAddress == msg.sender) {
            if (
                keccak256(abi.encodePacked(_choice, _nonce)) ==
                games[_gameId].firstPlayer.hashedChoice
            ) {
                games[_gameId].firstPlayer.choice = _choice;
                games[_gameId].firstPlayer.nonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        } else {
            if (
                keccak256(abi.encodePacked(_choice, _nonce)) ==
                games[_gameId].secondPlayer.hashedChoice
            ) {
                games[_gameId].secondPlayer.choice = _choice;
                games[_gameId].secondPlayer.nonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        }

        if (
            games[_gameId].firstPlayer.choice != Choice.UNDEFINED &&
            games[_gameId].secondPlayer.choice != Choice.UNDEFINED
        ) {
            games[_gameId].isFinished = true;
            findWinner(_gameId);
        }
        return games[_gameId].winner;
    }

    function findWinner(address _gameId)
        public
        gameExists(_gameId)
        returns (address)
    {
        require(
            games[_gameId].isFinished == true,
            "The game hasn't finished yet !"
        );

        if (games[_gameId].winner == address(0)) {
            if (
                games[_gameId].firstPlayer.choice ==
                games[_gameId].secondPlayer.choice
            ) games[_gameId].isDraw = true;
            else if (games[_gameId].firstPlayer.choice == Choice.ROCK) {
                if (games[_gameId].secondPlayer.choice == Choice.PAPER)
                    games[_gameId].winner = games[_gameId]
                        .secondPlayer
                        .playerAddress;
                else
                    games[_gameId].winner = games[_gameId]
                        .firstPlayer
                        .playerAddress;
            } else if (games[_gameId].firstPlayer.choice == Choice.PAPER) {
                if (games[_gameId].secondPlayer.choice == Choice.SCISSORS)
                    games[_gameId].winner = games[_gameId]
                        .secondPlayer
                        .playerAddress;
                else
                    games[_gameId].winner = games[_gameId]
                        .firstPlayer
                        .playerAddress;
            } else if (games[_gameId].firstPlayer.choice == Choice.SCISSORS) {
                if (games[_gameId].secondPlayer.choice == Choice.ROCK)
                    games[_gameId].winner = games[_gameId]
                        .secondPlayer
                        .playerAddress;
                else
                    games[_gameId].winner = games[_gameId]
                        .firstPlayer
                        .playerAddress;
            }
        }
        return games[_gameId].winner;
    }
}
