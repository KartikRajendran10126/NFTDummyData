// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ScotchNoblemen is ERC721A, Ownable, ReentrancyGuard {
    // Immutable Values
    uint256 public immutable MAX_SUPPLY = 1000;
    uint256 public OWNER_MINT_MAX_SUPPLY = 50; // If not minted can be utilized by public mint
    uint256 public AIRDROP_MAX_SUPPLY = 100; // If not minted can be utilized by public mint

    string internal baseUri;
    uint256 public mintRate;
    uint256 public maxMintLimit = 10;
    bool public publicMintPaused = true;

    mapping (address => uint256) paymentTokens;

    // Reveal NFT Variables
    bool public revealed;
    string public hiddenBaseUri;

    struct BatchMint {
        address to;
        uint256 amount;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _hiddenBaseUri,
        uint256 _mintRate
    ) ERC721A(_name, _symbol) {
        mintRate = _mintRate;
        hiddenBaseUri = _hiddenBaseUri;
    }

    // ===== Owner mint =====
    function ownerMint(address to, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(
            amount <= OWNER_MINT_MAX_SUPPLY,
            "Minting amount exceeds reserved owner supply"
        );
        require((totalSupply() + amount) <= MAX_SUPPLY, "Sold out!");
        _safeMint(to, amount);
        OWNER_MINT_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - amount;
    }

    // ===== Owner mint in batches =====
    function ownerMintInBatch(BatchMint[] memory batchMint)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < batchMint.length; i++) {
            require(
                batchMint[i].amount <= OWNER_MINT_MAX_SUPPLY,
                "Minting amount exceeds reserved owner supply"
            );
            require(
                (totalSupply() + batchMint[i].amount) <= MAX_SUPPLY,
                "Sold out!"
            );
            _safeMint(batchMint[i].to, batchMint[i].amount);
            OWNER_MINT_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - batchMint[i].amount;
        }
    }

     // ===== Owner mint in batches =====
    function airdropInBatch(BatchMint[] memory batchMint)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < batchMint.length; i++) {
            require(
                batchMint[i].amount <= AIRDROP_MAX_SUPPLY,
                "Minting amount exceeds reserved airdrop supply"
            );
            require(
                (totalSupply() + batchMint[i].amount) <= MAX_SUPPLY,
                "Sold out!"
            );
            _safeMint(batchMint[i].to, batchMint[i].amount);
            AIRDROP_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - batchMint[i].amount;
        }
    }

    function _getMintQuantity(uint256 value)
        internal
        view
        returns (uint256)
    {
        uint256 tempRate = mintRate;
        uint256 remainder = value % tempRate;
        require(remainder == 0, "Send a divisible amount of eth");
        uint256 quantity = value / tempRate;
        require(quantity > 0, "quantity to mint is 0");
        require(
            (totalSupply() + quantity) <= MAX_SUPPLY,
            "Not enough NFTs left!"
        );
        return quantity;
    }

    // ===== Public mint =====
    function mintWithETH() external payable {
        require(!publicMintPaused, "Public mint is paused");
        uint256 quantity = _getMintQuantity(msg.value);
        require(
            quantity <= maxMintLimit,
            "The number of quantity is not between the allowed nft mint range."
        );
        _safeMint(msg.sender, quantity);
    }

    // ===== Public mint with ERC20 =====
    function mintWithERC20(uint256 amount, address tokenAddress) external {
        require(!publicMintPaused, "Public mint is paused");
        require(
            amount <= maxMintLimit,
            "The number of quantity is not between the allowed nft mint range."
        );
        _safeMint(msg.sender, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Used to get the maximum supply of tokens.
     * @return uint256 for max supply of tokens.
     */
    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Only Owner Functions
    function updateMintRate(uint256 _mintRate) public onlyOwner {
        require(_mintRate > 0, "Invalid mint rate value.");
        mintRate = _mintRate;
    }

    function updateMaxMintLimit(uint256 _maxMintLimit) public onlyOwner {
        require(_maxMintLimit > 0, "Invalid max mint limit.");
        maxMintLimit = _maxMintLimit;
    }

    function updatePublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function updateBaseTokenURI(string memory _baseTokenURI)
        external
        onlyOwner
    {
        baseUri = _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev withdraw all eth from contract and transfer to owner.
     */
    function withdraw() public onlyOwner nonReentrant {

        uint256 contractBalance = address(this).balance; 

        (bool aa, ) = payable(owner()).call{
            value: contractBalance
        }("");
        require(aa);

    }
}
