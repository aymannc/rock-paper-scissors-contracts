//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract RockPaperScissors {
    struct Game {
        address firstPlayer;
        address secondPlayer;
        address winner;
        string firstPlayerChoice;
        string secondPlayerChoice;
        bytes32 firstPlayerChoiceHash;
        bytes32 secondPlayerChoiceHash;
        uint256 timestamp;
        uint256 firstPlayerNonce;
        uint256 secondPlayerNonce;
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
        Game memory game;
        game.firstPlayer = msg.sender;
        game.firstPlayerChoiceHash = keccak256(
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
            msg.sender != games[_gameId].firstPlayer,
            "You've already played your role !"
        );

        games[_gameId].secondPlayer = msg.sender;
        games[_gameId].secondPlayerChoiceHash = keccak256(
            abi.encodePacked(choices[_choiceId], _nonce)
        );
    }

    function reveal(
        address _gameId,
        uint256 _choiceId,
        uint256 _nonce
    ) external validChoice(_choiceId) gameExists(_gameId) {
        require(games[_gameId].isFinished == false, "This game has finished !");

        require(
            games[_gameId].firstPlayer == msg.sender ||
                games[_gameId].secondPlayer == msg.sender,
            "You don't have access into this game !"
        );

        require(
            games[_gameId].secondPlayerChoiceHash != 0,
            "Can't reveal choices yet, all players need to submit choices !"
        );

        require(
            (games[_gameId].firstPlayer == msg.sender &&
                bytes(games[_gameId].firstPlayerChoice).length == 0) ||
                (games[_gameId].secondPlayer == msg.sender &&
                    bytes(games[_gameId].secondPlayerChoice).length == 0),
            "You've already revealed your choice !"
        );

        if (games[_gameId].firstPlayer == msg.sender) {
            if (
                keccak256(abi.encodePacked(choices[_choiceId], _nonce)) ==
                games[_gameId].firstPlayerChoiceHash
            ) {
                games[_gameId].firstPlayerChoice = choices[_choiceId];
                games[_gameId].firstPlayerNonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        } else {
            if (
                keccak256(abi.encodePacked(choices[_choiceId], _nonce)) ==
                games[_gameId].secondPlayerChoiceHash
            ) {
                games[_gameId].secondPlayerChoice = choices[_choiceId];
                games[_gameId].secondPlayerNonce = _nonce;
            } else
                revert(
                    "Invalid data, Please provide the right (choice,nonce) combination to reveal your choice !"
                );
        }

        if (
            bytes(games[_gameId].firstPlayerChoice).length != 0 &&
            bytes(games[_gameId].secondPlayerChoice).length != 0
        ) {
            games[_gameId].isFinished = true;
            findWinner(_gameId);
        }
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
                    games[_gameId].firstPlayerChoice,
                    games[_gameId].secondPlayerChoice
                )
            ) games[_gameId].isDraw = true;
            else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayerChoice,
                    choices[0]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayerChoice,
                        choices[1]
                    )
                ) games[_gameId].winner = games[_gameId].secondPlayer;
                else games[_gameId].winner = games[_gameId].firstPlayer;
            } else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayerChoice,
                    choices[1]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayerChoice,
                        choices[2]
                    )
                ) games[_gameId].winner = games[_gameId].secondPlayer;
                else games[_gameId].winner = games[_gameId].firstPlayer;
            } else if (
                compareStringsbyBytes(
                    games[_gameId].firstPlayerChoice,
                    choices[2]
                )
            ) {
                if (
                    compareStringsbyBytes(
                        games[_gameId].secondPlayerChoice,
                        choices[0]
                    )
                ) games[_gameId].winner = games[_gameId].secondPlayer;
                else games[_gameId].winner = games[_gameId].firstPlayer;
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
