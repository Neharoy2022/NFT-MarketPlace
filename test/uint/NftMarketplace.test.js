const { assert, expect } = require("chai")
const { network, ethers, getNamedAccounts, deployments } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("NFT Marketplace Test", function () {
          let nftMarketPlace, BasicNft, deployer, player
          const PRICE = ethers.utils.parseEther("0.1")
          const TOKEN_ID = 0
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              //player = (await getNamedAccounts()).player
              const accounts = await ethers.getSigners()
              player = accounts[1]
              await deployments.fixture(["all"])
              nftMarketPlace = await ethers.getContract("NftMarketplace")
              BasicNft = await ethers.getContract("BasicNft")
              await BasicNft.mintNft()
              await BasicNft.approve(nftMarketPlace.address, TOKEN_ID)
          })
          it("Nft can be listed and bought", async function () {
              await nftMarketPlace.listItems(BasicNft.address, TOKEN_ID, PRICE)
              const PlayerConnectedNftMarketPlace = nftMarketPlace.connect(player)
              await PlayerConnectedNftMarketPlace.buyItem(BasicNft.address, TOKEN_ID, {
                  value: PRICE,
              })
              const newOwner = await BasicNft.ownerOf(TOKEN_ID) // Assertion error occured when we didn't put await for newOwner.
              const deployerProceeds = await nftMarketPlace.getfundsEarned(deployer)
              assert(newOwner.toString() == player.address)
              assert(deployerProceeds.toString() == PRICE.toString())
          })

          it("To check items that haven't been listed", async function () {
              await nftMarketPlace.listItems(BasicNft.address, TOKEN_ID, PRICE)
              await expect(
                  nftMarketPlace.listItems(BasicNft.address, TOKEN_ID, PRICE)
              ).to.be.revertedWith(
                  `NftMarketplace_ItemAlreadylisted("${BasicNft.address}", ${TOKEN_ID})`
              )
          })
      })
