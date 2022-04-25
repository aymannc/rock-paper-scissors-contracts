const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RockPaperScissors", function () {

  const options = ["Rock", "Paper", "Scissors"]

  it("Should return the game options", async function () {
    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const game = await RockPaperScissors.deploy(options);
    await game.deployed();

    console.log(await game.getOptions().length)
    expect(await game.getOptions()).to.contain(options[0]);
  });

  it("should set the options", async () => {

    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const game = await RockPaperScissors.deploy(options);
    await game.deployed();

    const setOptionsTx = await game.setOptions(options.slice(0, 1));

    // wait until the transaction is mined
    await setOptionsTx.wait();

    expect(await game.getOptions()).to.contain(options[0]);
  })
});
