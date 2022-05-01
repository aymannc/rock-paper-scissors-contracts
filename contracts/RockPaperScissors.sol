//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {
    struct Player {
        address playerAddress;
        string choice;
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

    string[] public choices = ["R", "P", "S"];

    address owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner is allowed to do this operation"
        );
        _;
    }

    modifier validChoice(uint256 choiceId) {
        require(choiceId < choices.length, "Invalid choice Id !");
        _;
    }

    modifier gameExists(address _gameId) {
        require(games[_gameId].timestamp > 0, "Invalid _gameId !");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * Read only function to retrieve the choices of the game.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function getchoices() external view returns (string[] memory) {
        return choices;
    }

    function setchoices(string[] memory _choices) external onlyOwner {
        choices = _choices;
    }

    function createGame(uint256 _choiceId, uint256 _nonce)
        external
        validChoice(_choiceId)
        returns (address)
    {
        require(
            games[msg.sender].timestamp == 0 || games[msg.sender].isFinished,
            "You can't create a new game until the old one finishes !"
        );

        Game memory game;
        game.firstPlayer.playerAddress = msg.sender;
        game.firstPlayer.hashedChoice = keccak256(
            abi.encodePacked(choices[_choiceId], _nonce)
        );
        game.timestamp = block.timestamp;

        games[msg.sender] = game;

        console.log(msg.sender);

        return msg.sender;
    }

    function submit(
        address _gameId,
        uint256 _choiceId,
        uint256 _nonce
    ) external validChoice(_choiceId) gameExists(_gameId) {
        require(games[_gameId].isFinished == false, "This game has finished !");
        require(
            msg.sender != games[_gameId].firstPlayer.playerAddress,
            "You've already played your role !"
        );

        games[_gameId].secondPlayer.playerAddress = msg.sender;
        games[_gameId].secondPlayer.hashedChoice = keccak256(
            abi.encodePacked(choices[_choiceId], _nonce)
        );
    }

    function reveal(
        address _gameId,
        uint256 _choiceId,
        uint256 _nonce
    ) external validChoice(_choiceId) gameExists(_gameId) returns (address) {
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
                bytes(games[_gameId].firstPlayer.choice).length == 0) ||
                (games[_gameId].secondPlayer.playerAddress == msg.sender &&
                    bytes(games[_gameId].secondPlayer.choice).length == 0),
            "You've already revealed your choice !"
        );

        if (games[_gameId].firstPlayer.playerAddress == msg.sender) {
            if (
                keccak256(abi.encodePacked(choices[_choiceId], _nonce)) ==
                games[_gameId].firstPlayer.hashedChoice
            ) {
                games[_gameId].firstPlayer.choice = choices[_choiceId];
                games[_gameId].firstPlayer.nonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        } else {
            if (
                keccak256(abi.encodePacked(choices[_choiceId], _nonce)) ==
                games[_gameId].secondPlayer.hashedChoice
            ) {
                games[_gameId].secondPlayer.choice = choices[_choiceId];
                games[_gameId].secondPlayer.nonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        }

        if (
            bytes(games[_gameId].firstPlayer.choice).length != 0 &&
            bytes(games[_gameId].secondPlayer.choice).length != 0
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
        // R , P , S
        require(
            games[_gameId].isFinished == true,
            "The game hasn't finished yet !"
        );

        if (games[_gameId].winner == address(0)) {
            if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayer.choice,
                    games[_gameId].secondPlayer.choice
                )
            ) games[_gameId].isDraw = true;
            else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayer.choice,
                    choices[0]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayer.choice,
                        choices[1]
                    )
                )
                    games[_gameId].winner = games[_gameId]
                        .secondPlayer
                        .playerAddress;
                else
                    games[_gameId].winner = games[_gameId]
                        .firstPlayer
                        .playerAddress;
            } else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayer.choice,
                    choices[1]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayer.choice,
                        choices[2]
                    )
                )
                    games[_gameId].winner = games[_gameId]
                        .secondPlayer
                        .playerAddress;
                else
                    games[_gameId].winner = games[_gameId]
                        .firstPlayer
                        .playerAddress;
            } else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayer.choice,
                    choices[2]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayer.choice,
                        choices[0]
                    )
                )
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

    function compareStringsbyBytes(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
