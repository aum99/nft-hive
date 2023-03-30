// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//Internal import for nft openzeppelin
import '@openzeppelin/contracts/utils/Counters.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import 'hardhat/console.sol';

abstract contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    
    uint256 listingPrice = 0.0015 ether;
    
    address payable owner;
    
    //each nft will have a unique id
    //all nfts stored inside the IdMarketItem
    //use this and pass id and find the respective nft and data 
    mapping (uint256 => MarketItem) private idMarketItem; 
    
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    
    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner {
        require(msg.sender == owner, 
        "only owner of the marketplace can change the listing price");
        _; // once modifier is true other functions will continue
    }
    
    constructor() ERC721("NFT Metaverse Token", "MYNFT"){
        owner == payable(msg.sender);
    }
    
    // only owner can use this function to change the price of the nfts
    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
        listingPrice = _listingPrice;
    }

    //fetch the listing price 
    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    //let create "CREATE NFT TOKEN FUNCTION"
    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        _tokenIds.increment();
        
        uint256 newTokenId = _tokenIds.current();
        
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId,tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    //creates a nft and assigns all the specified data to it
    function createMarketItem(uint256 tokenId, uint256 price) private{
        require(price > 0, "Price must be atleast 1");
        require(msg.value == listingPrice, 'Price must be equal to listing price'); // to get the commission

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),//refers to smartcontract
            price,
            false
        );

        //takes idmarket item in which we assign the below token id
        //the token id contains all info abt the nft
        // transfer the token to the owner
        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
            );
    }

    //function for resale of the token
    function resaleToken(uint256 tokenId, uint256 price)public payable{
        require(idMarketItem[tokenId].owner == msg.sender, 'Only item owner can perform this function');
        require(msg.value == listingPrice, 'Price must be equal to listing price');
        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this)); 

        //when someone buys it increments but on resale decrements
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    //

    function createMarketSale(uint256 tokenId)public payable{
        uint256 price = idMarketItem[tokenId].price;
        
        require(msg.value == price, 'Please submit the price in order to complete the purchase');
        
        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));
        
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    //getting unsold nft data 
    function fetchMarketItems() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItems =  _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItems);

        for(uint256 i=0;i<itemCount;i++){
            //checking the nfts that belong to this smart contract
            if(idMarketItem[i+1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    //purchase an nft
    function fetchMyNft() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    //nft details
    function fetchItemsListed()public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i + 1;
                
                MarketItem storage currentItem = idMarketItem[currentId];

                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}


