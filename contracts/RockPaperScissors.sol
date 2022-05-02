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

    enum GameStatus {
        UNDEFINED,
        CREATED,
        COMMITED,
        REVEALING,
        FINISHED
    }

    struct Player {
        address playerAddress;
        Choice choice;
        bytes32 hashedChoice;
        uint256 nonce;
    }

    struct Game {
        uint256 timestamp;
        Player firstPlayer;
        Player secondPlayer;
        GameStatus status;
        address winner;
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
        require(
            games[_gameId].status >= GameStatus.CREATED,
            "Invalid _gameId !"
        );
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
            games[msg.sender].timestamp == 0 ||
                games[msg.sender].status == GameStatus.FINISHED,
            "You can't create a new game until the old one finishes !"
        );

        Game memory game;
        game.firstPlayer.playerAddress = msg.sender;
        game.firstPlayer.hashedChoice = keccak256(
            abi.encodePacked(_choice, _nonce)
        );
        game.timestamp = block.timestamp;
        game.status = GameStatus.CREATED;

        games[msg.sender] = game;

        console.log(msg.sender);

        return msg.sender;
    }

    function play(
        address _gameId,
        Choice _choice,
        uint256 _nonce
    ) external validChoice(_choice) gameExists(_gameId) {
        require(
            games[_gameId].status != GameStatus.FINISHED,
            "This game has finished !"
        );
        require(
            msg.sender != games[_gameId].firstPlayer.playerAddress,
            "You've already played your role !"
        );

        games[_gameId].secondPlayer.playerAddress = msg.sender;
        games[_gameId].secondPlayer.hashedChoice = keccak256(
            abi.encodePacked(_choice, _nonce)
        );
        games[_gameId].status = GameStatus.COMMITED;
    }

    function reveal(
        address _gameId,
        Choice _choice,
        uint256 _nonce
    ) external validChoice(_choice) gameExists(_gameId) returns (address) {
        require(
            games[_gameId].status == GameStatus.COMMITED ||
                games[_gameId].status == GameStatus.REVEALING,
            "This game has finished or hasn't been played yet!"
        );

        require(
            games[_gameId].firstPlayer.playerAddress == msg.sender ||
                games[_gameId].secondPlayer.playerAddress == msg.sender,
            "You don't have access into this game !"
        );

        require(
            (games[_gameId].firstPlayer.playerAddress == msg.sender &&
                games[_gameId].firstPlayer.choice == Choice.UNDEFINED) ||
                (games[_gameId].secondPlayer.playerAddress == msg.sender &&
                    games[_gameId].secondPlayer.choice == Choice.UNDEFINED),
            "You've already revealed your choice !"
        );

        games[_gameId].status = GameStatus.REVEALING;

        bytes32 hashedChoice = keccak256(abi.encodePacked(_choice, _nonce));

        if (
            (games[_gameId].firstPlayer.playerAddress == msg.sender) &&
            (hashedChoice == games[_gameId].firstPlayer.hashedChoice)
        ) {
            games[_gameId].firstPlayer.choice = _choice;
            games[_gameId].firstPlayer.nonce = _nonce;
        } else if (
            (games[_gameId].secondPlayer.playerAddress == msg.sender) &&
            (hashedChoice == games[_gameId].secondPlayer.hashedChoice)
        ) {
            games[_gameId].secondPlayer.choice = _choice;
            games[_gameId].secondPlayer.nonce = _nonce;
        } else
            revert(
                "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
            );

        if (
            games[_gameId].firstPlayer.choice != Choice.UNDEFINED &&
            games[_gameId].secondPlayer.choice != Choice.UNDEFINED
        ) {
            games[_gameId].status = GameStatus.FINISHED;
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
            games[_gameId].status == GameStatus.FINISHED,
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
