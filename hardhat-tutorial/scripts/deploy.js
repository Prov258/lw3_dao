const { ethers } = require("hardhat")
const { CRYPTO_DEVS_NFT_CONTRACT_ADDRESS } = require("../constants")

async function main() {
    const nftMarketplaceContract = await ethers.getContractFactory(
        "FakeNFTMarketplace"
    )
    const deployedNFTMarketplaceContract = await nftMarketplaceContract.deploy()
    await deployedNFTMarketplaceContract.deployed()

    console.log(
        "NFTMarketplace contract address:",
        deployedNFTMarketplaceContract.address
    )

    const cryptoDevsDAOContract = await ethers.getContractFactory(
        "CryptoDevsDAO"
    )
    const deployedCryptoDevsDAOContract = await cryptoDevsDAOContract.deploy(
        CRYPTO_DEVS_NFT_CONTRACT_ADDRESS,
        deployedNFTMarketplaceContract.address,
        { value: ethers.utils.parseEther("0.2") }
    )
    await deployedCryptoDevsDAOContract.deployed()

    console.log(
        "CryptoDevsDAO contract address:",
        deployedCryptoDevsDAOContract.address
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
