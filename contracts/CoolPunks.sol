// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CoolPunks is ERC721, ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    mapping(string => uint8) existingURIs;

    struct UserInfo {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256) timeStaked;
        uint256 amountStaked;
    }

    struct CollectionInfo {
        bool isStakable;
        address collectionAddress;
        uint256 mintingFee;
        uint256 harvestingFee;
        uint256 multiplier;
        uint256 amountOfStakers;
        uint256 stakingLimit;
        uint256 harvestCooldown;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address)) public tokenOwners;

    CollectionInfo[] public collectionInfo;

    constructor(bool _isStakable) public ERC721("Cool Punks", "COOL") {
        tokenCounter = 0;
        setCollection(
            _isStakable,
            address(this),
            50000000000000000,
            1000000000000000,
            2,
            5,
            10
        );
    }

    function checkMintPrice(uint256 _cid) public returns (uint256) {
        return collectionInfo[_cid].mintingFee;
    }

    function count() public view returns (uint256) {
        return tokenCounter;
    }

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function createCollectible(uint256 _cid, string memory _tokenURI)
        public
        payable
        returns (uint256)
    {
        require(
            msg.value >= collectionInfo[_cid].mintingFee,
            "Masterdemon.stake: Fee"
        );
        uint256 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        tokenCounter++;
        existingURIs[_tokenURI] = 1;
        return newTokenId;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function stake(uint256 _cid, uint256 _id) external {
        approve(address(this), _id);
        _stake(msg.sender, _cid, _id);
    }

    function unstake(uint256 _cid, uint256 _id) external payable {
        require(
            msg.value >= collectionInfo[_cid].harvestingFee,
            "Masterdemon.stake: Fee"
        );
        _unstake(msg.sender, _cid, _id);
    }

    function _stake(
        address _user,
        uint256 _cid,
        uint256 _id
    ) internal {
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];

        require(
            user.stakedTokens[collection.collectionAddress].length <
                collection.stakingLimit,
            "Masterdemon._stake: You can't stake more"
        );

        IERC721(collection.collectionAddress).transferFrom(
            _user,
            address(this),
            _id
        );

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers += 1;
        }

        user.amountStaked += 1;
        user.timeStaked[collection.collectionAddress] = block.timestamp;
        user.stakedTokens[collection.collectionAddress].push(_id);
        tokenOwners[collection.collectionAddress][_id] = _user;
    }

    function _unstake(
        address _user,
        uint256 _cid,
        uint256 _id
    ) internal {
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];

        require(
            tokenOwners[collection.collectionAddress][_id] == _user,
            "Masterdemon._unstake: Sender doesn't owns this token"
        );

        //remove element from array

        uint256[] storage _array = user.stakedTokens[
            collection.collectionAddress
        ];
        uint256 _element = _id;

        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }

        //end of remove element

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers -= 1;
        }

        delete tokenOwners[collection.collectionAddress][_id];

        user.timeStaked[collection.collectionAddress] = block.timestamp;
        user.amountStaked -= 1;

        if (user.amountStaked == 0) {
            delete userInfo[_user];
        }

        IERC721(collection.collectionAddress).transferFrom(
            address(this),
            _user,
            _id
        );
    }

    function setCollection(
        bool _isStakable,
        address _collectionAddress,
        uint256 _mintingFee,
        uint256 _harvestingFee,
        uint256 _multiplier,
        uint256 _stakingLimit,
        uint256 _harvestCooldown
    ) public onlyOwner {
        collectionInfo.push(
            CollectionInfo({
                isStakable: _isStakable,
                collectionAddress: _collectionAddress,
                mintingFee: _mintingFee,
                harvestingFee: _harvestingFee,
                multiplier: _multiplier,
                amountOfStakers: 0,
                stakingLimit: _stakingLimit,
                harvestCooldown: _harvestCooldown
            })
        );
    }

    function updateCollection(
        uint256 _cid,
        bool _isStakable,
        address _collectionAddress,
        uint256 _mintingFee,
        uint256 _harvestingFee,
        uint256 _multiplier,
        uint256 _stakingLimit,
        uint256 _harvestCooldown
    ) public onlyOwner {
        CollectionInfo storage collection = collectionInfo[_cid];
        collection.isStakable = _isStakable;
        collection.collectionAddress = _collectionAddress;
        collection.mintingFee = _mintingFee;
        collection.harvestingFee = _harvestingFee;
        collection.multiplier = _multiplier;
        collection.stakingLimit = _stakingLimit;
        collection.harvestCooldown = _harvestCooldown;
    }

    function manageCollection(uint256 _cid, bool _isStakable) public onlyOwner {
        collectionInfo[_cid].isStakable = _isStakable;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function isStaked(uint256 tokenId) public view returns (bool) {
        CollectionInfo storage collection = collectionInfo[0];
        if (
            tokenOwners[collection.collectionAddress][tokenId] == address(this)
        ) {
            return true;
        } else {
            return false;
        }
    }
}
