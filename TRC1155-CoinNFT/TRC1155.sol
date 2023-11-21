pragma solidity ^0.8.17;

//SPDX-License-Identifier: Apache-2.0

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ITRC1155 {
// Events
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event URI(string _value, uint256 indexed _id);
// Required Functions
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}
interface ITRC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface TRC1155TokenReceiver {
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

interface TRC1155Metadata_URI {
    // Query the URI of a token. The URI points to a JSON file that conforms to the `TRC-1155 Metadata URI JSON file` specification.
     
    function uri(uint256 _id) external view returns (string memory);
}

contract TRC1155 is ITRC1155, ITRC165{

    using SafeMath for uint256;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;
    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {
        require(_owners.length == _ids.length);
        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }
        return balances_;
    }

    bytes4 constant public TRC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256(“onERC1155Received(address,address,uint256,uint256,bytes)”))`).
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(_to != address(0));
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true);
        // SafeMath will throw with insufficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to] = _value.add(balances[_id][_to]);
        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        // Now that the balance is updated and the event was emitted,
        // call onTRC1155Received if the destination is a contract.
        
        _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        
    }

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
        require(TRC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == TRC1155_ACCEPTED);
    }

    bytes4 constant internal TRC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256(“onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)”))
    
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {
        // MUST Throw on errors
        require(_to != address(0x0));
        require(_ids.length == _values.length);
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true);
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            // SafeMath will throw with insufficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }
        // Note: instead of the below batch versions of event and    acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in the above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.
        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        // Now that the balances are updated and the events are emitted,
        // call onTRC1155BatchReceived if the destination is a contract.
        
        _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {
        require(TRC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == TRC1155_BATCH_ACCEPTED);
    }

    /* bytes4(keccak256(‘supportsInterface(bytes4)’)) == 0x01ffc9a7; */
    bytes4 constant private INTERFACE_SIGNATURE_TRC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256(“safeTransferFrom(address,address,uint256,uint256,bytes)”)) ^
    bytes4(keccak256(“safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)”)) ^
    bytes4(keccak256(“balanceOf(address,uint256)”)) ^
    bytes4(keccak256(“balanceOfBatch(address[],uint256[])”)) ^
    bytes4(keccak256(“setApprovalForAll(address,bool)”)) ^
    bytes4(keccak256(“isApprovedForAll(address,address)”));
    */
    bytes4 constant private INTERFACE_SIGNATURE_TRC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool)
    {
        if (_interfaceId == INTERFACE_SIGNATURE_TRC165 || _interfaceId == INTERFACE_SIGNATURE_TRC1155) {
            return true;
        }
        return false;
    }
    
}

