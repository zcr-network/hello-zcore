// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Minimal receiver interface so `safeTransferFrom` can check a contract accepts NFTs.
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

/// @title MyNFT — a minimal, self-contained ERC-721 (NFT) collection to deploy on ZCore Network.
/// @notice No external dependencies — just Foundry. The deployer is the owner and can `mint()`.
///         Token IDs auto-increment from 0. `tokenURI(id)` = baseURI + id.
///
///         For production, prefer OpenZeppelin's audited ERC721 (see the README).
contract MyNFT {
    string public name;
    string public symbol;
    string private _baseURI;
    address public owner;
    uint256 public nextTokenId; // id of the NEXT token to mint (first mint = 0)

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @param _name   collection name, e.g. "My ZCore NFT"
    /// @param _symbol collection symbol, e.g. "MZN"
    /// @param baseURI_ metadata base, e.g. "https://my-nft.example/metadata/" (tokenURI = base + id)
    constructor(string memory _name, string memory _symbol, string memory baseURI_) {
        name = _name;
        symbol = _symbol;
        _baseURI = baseURI_;
        owner = msg.sender;
    }

    // ------------------------------------------------------------ views
    function ownerOf(uint256 id) public view returns (address o) {
        o = _ownerOf[id];
        require(o != address(0), "not minted");
    }

    function balanceOf(address a) external view returns (uint256) {
        require(a != address(0), "zero address");
        return _balanceOf[a];
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        require(_ownerOf[id] != address(0), "not minted");
        return string.concat(_baseURI, _toString(id));
    }

    // ------------------------------------------------------------ mint
    /// @notice Mints the next NFT to `to`. Only the owner (deployer) can mint.
    function mint(address to) external onlyOwner returns (uint256 id) {
        require(to != address(0), "zero address");
        id = nextTokenId++;
        _ownerOf[id] = to;
        unchecked {
            _balanceOf[to]++;
        }
        emit Transfer(address(0), to, id);
    }

    // ------------------------------------------------------------ approvals
    function approve(address spender, uint256 id) external {
        address o = _ownerOf[id];
        require(msg.sender == o || isApprovedForAll[o][msg.sender], "not authorized");
        getApproved[id] = spender;
        emit Approval(o, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ------------------------------------------------------------ transfers
    function transferFrom(address from, address to, uint256 id) public {
        require(from == _ownerOf[id], "wrong from");
        require(to != address(0), "zero address");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "not authorized"
        );
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external {
        transferFrom(from, to, id);
        _checkReceiver(from, to, id, "");
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);
        _checkReceiver(from, to, id, data);
    }

    // ------------------------------------------------------------ ERC-165
    function supportsInterface(bytes4 iid) external pure returns (bool) {
        return iid == 0x01ffc9a7 // ERC-165
            || iid == 0x80ac58cd // ERC-721
            || iid == 0x5b5e139f; // ERC-721 Metadata
    }

    // ------------------------------------------------------------ internals
    function _checkReceiver(address from, address to, uint256 id, bytes memory data) private {
        if (to.code.length == 0) return; // EOAs are fine
        require(
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                == IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function _toString(uint256 v) private pure returns (string memory) {
        if (v == 0) return "0";
        uint256 len;
        for (uint256 t = v; t != 0; t /= 10) {
            len++;
        }
        bytes memory b = new bytes(len);
        while (v != 0) {
            len--;
            b[len] = bytes1(uint8(48 + (v % 10)));
            v /= 10;
        }
        return string(b);
    }
}
