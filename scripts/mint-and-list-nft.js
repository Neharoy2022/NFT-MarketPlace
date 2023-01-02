const { ethers } = require("hardhat")

const PRICE = ethers.utils.parseEther("0.1")

async function mintandlist() {
    const nftMarketPlace = await ethers.getContract("NftMarketplace")
    const basicNft = await ethers.getContract("BasicNft")
    console.log("Minting NFT ...")
    const mintNft = await basicNft.mintNft()
    const mintNftTx = await mintNft.wait(1)
    const tokenId = mintNftTx.events[0].args.tokenId
    console.log("Approving Nft...")

    const approvalTx = await basicNft.approve(nftMarketPlace.address, tokenId)
    await approvalTx.wait(1)
    console.log("Listing Nft...")
    const tx = await nftMarketPlace.listItems(basicNft.address, tokenId, PRICE)
    await tx.wait(1)
    console.log("Listed...")
}

mintandlist()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

//yarn hardhat node
//yarn hardhat run scripts/mint-and-list-nft.js --network localhost
