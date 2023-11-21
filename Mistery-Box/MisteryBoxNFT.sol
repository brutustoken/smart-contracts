pragma solidity >=0.8.0;

// SPDX-License-Identifier: Apache-2.0 


interface ITRC20 {

    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address direccion, uint cantidad) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns(uint);
}

interface ITRC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}


contract Ownable {
  address payable public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor(){
    owner = payable(msg.sender);
  }
  modifier onlyOwner() {
    if(msg.sender != owner)revert();
    _;
  }
  function transferOwnership(address payable newOwner) public onlyOwner {
    if(newOwner == address(0))revert();
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract dinamicArray{
    
    function actualizarArray(address[] memory oldArray)public pure returns ( address[] memory) {

        //añade un espacio para un nuevo dato
        address[] memory newArray =   new address[](oldArray.length+1);
    
        for(uint i = 0; i < oldArray.length; i++){
            newArray[i] = oldArray[i];
        }
        
        return newArray;
    }

    function borrarArray(address[] memory oldArray)public pure returns ( address[] memory) {

        //borra los espacios que esten con address(0)
        address[] memory newArray;
        uint largo;

        for(uint i = 0; i < oldArray.length; i++){
            if(oldArray[i] != address(0)){
                newArray = actualizarArray(newArray);
                newArray[largo] = oldArray[i];
                largo++;
            }
        }
        
        return newArray;
    }

    function actualizarArrayNumber(uint256[] memory oldArray)public pure returns ( uint256[] memory) {

        //añade un espacio para un nuevo dato
        uint256[] memory newArray =   new uint256[](oldArray.length+1);
    
        for(uint i = 0; i < oldArray.length; i++){
            newArray[i] = oldArray[i];
        }
        
        return newArray;
    }

    function borrarArrayNumber(uint256[] memory oldArray)public pure returns ( uint256[] memory) {

        //borra los espacios que esten con 0
        uint256[] memory newArray;
        uint largo;

        for(uint i = 0; i < oldArray.length; i++){
            if(oldArray[i] != 0){
                newArray = actualizarArrayNumber(newArray);
                newArray[largo] = oldArray[i];
                largo++;
            }
        }
        
        return newArray;
    }
    

}

contract RandomNumber{
 
    // Initializing the state variable
    uint randNonce = 0;
     
    // Defining a function to generate
    // a random number
    function randMod(uint _modulus, uint _moreRandom) public view returns(uint){
       
       return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce, _moreRandom))) % _modulus;
    }

    function doneRandom() public {
      // increase nonce
       randNonce++; 

    }
}

contract misteryBox is RandomNumber, dinamicArray, Ownable{

    uint256[] public idTokens = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];

    mapping (address => uint256[]) public entregaNFT;

    address public ownerNFTs = 0x55A8d57DFBBCEEBA1C3F39C7953c856c1fCe66A9;

    address public tokenTRC721 = 0x4B1e5bf29f614f9582b111823D0c106CDa0511AA;

    address public tokenTRC20 = 0x3Dfe637B2b9aE4190A458B5F3EfC1969afE27819;

    uint256 public precio = 10000000 * 10**6;

    ITRC721 TRC721_Contract = ITRC721(tokenTRC721);

    ITRC20 TRC20_Contract = ITRC20(tokenTRC20);

    function buyMisteryBox() public returns(uint256){
        if(idTokens.length == 0)revert("no hay tokens para entregar");
        if( TRC20_Contract.allowance(msg.sender, address(this)) < precio)revert("saldo aprobado insuficiente");
        if( !TRC20_Contract.transferFrom(msg.sender, address(this), precio))revert("transferencia inconclusa");

        uint256 myNumber = randMod(idTokens.length, precio);

        uint256 myNFT = idTokens[myNumber];
        idTokens[myNumber] = 0;
        idTokens = borrarArrayNumber(idTokens);

        doneRandom();

        entregaNFT[msg.sender].push(myNFT);

        return myNFT;

    }

    function claimNFT() public returns(uint256){
        for (uint256 index = 0; index < entregaNFT[msg.sender].length; index++) {
            TRC721_Contract.transferFrom(ownerNFTs, msg.sender, entregaNFT[msg.sender][index] );
        }
        
        return entregaNFT[msg.sender].length;
    }

    function claimNFT_especifico(uint256 _index) public returns(uint256){

        TRC721_Contract.transferFrom(ownerNFTs, msg.sender, entregaNFT[msg.sender][_index] );
        
        return entregaNFT[msg.sender][_index];
    }

    function update_ownerNFTs(address _ownerNFTs) public onlyOwner returns(bool){
        ownerNFTs = _ownerNFTs;
        return true;
    }

    function update_tokenTRC721(address _tokenTRC721) public onlyOwner returns(bool){
        tokenTRC721 = _tokenTRC721;
        TRC721_Contract = ITRC721(_tokenTRC721);
        return true;
    }

    function update_tokenTRC20(address _tokenTRC20) public onlyOwner returns(bool){
        tokenTRC20 = _tokenTRC20;
        TRC20_Contract = ITRC20(_tokenTRC20);
        return true;
    }

    function update_idTokens(uint256[] memory _idTokens) public onlyOwner returns(bool){
        idTokens = _idTokens;
        return true;
    }

    function update_precio(uint256 _precio) public onlyOwner returns(bool){
        precio = _precio;
        return true;
    }

    function retirar_TRC20_ALL()public onlyOwner returns(bool){
        return TRC20_Contract.transfer(msg.sender, TRC20_Contract.balanceOf(address(this)));
    }

    function retirar_TRC20(uint256 _cantidad)public onlyOwner returns(bool){
        return TRC20_Contract.transfer(msg.sender, _cantidad);
    }

}