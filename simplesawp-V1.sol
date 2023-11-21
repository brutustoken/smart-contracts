pragma solidity ^0.5.15;

import "./SafeMath.sol";

contract TRC20_Interface {

    function allowance(address _owner, address _spender) public view returns (uint remaining);

    function transferFrom(address _from, address _to, uint _value) public returns (bool);

    function transfer(address direccion, uint cantidad) public returns (bool);

    function balanceOf(address who) public view returns (uint256);
    
    function decimals() public view returns (uint256);
}

contract simpleswap {
  using SafeMath for uint;

  TRC20_Interface USDT_Contract;

  TRC20_Interface TRC20_Contract;

  TRC20_Interface OTRO_Contract;

  struct Investor {
    uint tokenCompra;
    uint usdCompra;
    uint tokenVenta;
    uint usdVenta;
  }
  
  uint public RATE;
  
  address payable public marketing;
  address payable public owner;
  address public NoValido = address(0);

  mapping (address => Investor) public investors;

  constructor(address _tokenTRC20, address _tokenUSDT, address payable _marketing) public {
    TRC20_Contract = TRC20_Interface(_tokenTRC20);
    USDT_Contract = TRC20_Interface(_tokenUSDT);
    marketing = _marketing;
    owner = msg.sender;

  }

  function ChangeRate(uint _precioUSDT) public returns (bool){

    require( msg.sender == owner );

    RATE = _precioUSDT;

    return true;

  }


  function ChangeToken(address _tokenTRC20) public returns (bool){

    require( msg.sender == owner );

    TRC20_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }

  function ChangeTokenOTRO(address _tokenTRC20) public returns (bool){

    require( msg.sender == owner );

    OTRO_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }

  function aprovedBRUTUS() public view returns (uint256){
    return TRC20_Contract.allowance(msg.sender, address(this));
  }

  function InContractBRUTUS() public view returns (uint){
    return TRC20_Contract.balanceOf(address(this));
  }

  function aprovedUSDT() public view returns (uint256){
    return USDT_Contract.allowance(msg.sender, address(this));
  }

  function InContractUSDT() public view returns (uint){
    return USDT_Contract.balanceOf(address(this));
  }

  function InContractOTRO() public view returns (uint){
    return OTRO_Contract.balanceOf(address(this));
  }

  function InContractTRX() public view returns (uint){
    return address(this).balance;
  }

  function comprar(uint _value) public returns (bool) {

    require( USDT_Contract.allowance(msg.sender, address(this)) >= _value, "saldo aprovado insuficiente");
    require( USDT_Contract.transferFrom(msg.sender, address(this), _value), "No tienes saldo" );

    uint cantidad = (_value.mul(10 ** TRC20_Contract.decimals())).div(RATE);

    require ( true != TRC20_Contract.transfer(msg.sender, cantidad), "whitdrawl Fail" );

    Investor storage investor = investors[msg.sender];

    investor.tokenCompra += cantidad;
    investor.usdCompra += _value;

    require ( true != TRC20_Contract.transfer(marketing, cantidad.mul(3).div(100) ) );

    return true;

  }


  function vender(uint _value) public returns (bool){

    require( TRC20_Contract.allowance(msg.sender, address(this)) >= _value, "saldo aprovado insuficiente");
    require( TRC20_Contract.transferFrom(msg.sender, address(this), _value), "No tienes saldo" );

    uint pago = _value.mul(RATE).div(10 ** TRC20_Contract.decimals());

    require(USDT_Contract.balanceOf(address(this)) >= pago, "vende una menor cantidad");

    require ( true != USDT_Contract.transfer(msg.sender, pago), "whitdrawl Fail" ) ;

    Investor storage investor = investors[msg.sender];

    investor.tokenVenta += _value;
    investor.usdVenta += pago;

    return true;
  }

  function updateInvestor(address _user, uint _tokenCompra, uint _usdCompra, uint _tokenVenta, uint _usdVenta) public returns (bool){

    require( msg.sender == owner );

    Investor storage investor = investors[_user];

    investor.tokenCompra = _tokenCompra;
    investor.usdCompra = _usdCompra;
    investor.tokenVenta = _tokenVenta;
    investor.usdVenta = _usdVenta;

    return true;
  }

  function TRC20redim01() public returns (uint256){
    require(msg.sender == owner);

    uint256 valor = TRC20_Contract.balanceOf(address(this));

    TRC20_Contract.transfer(owner, valor);

    return valor;
  }

  function TRC20redim02(uint _value) public returns (uint256) {

    require ( msg.sender == owner, "only owner");

    require ( TRC20_Contract.balanceOf(address(this)) >= _value, "The contract has no balance");

    TRC20_Contract.transfer(owner, _value);

    return _value;

  }

  function redimOTRO01() public returns (uint256){
    require(msg.sender == owner);

    uint256 valor = OTRO_Contract.balanceOf(address(this));

    OTRO_Contract.transfer(owner, valor);

    return valor;
  }

  function redimOTRO02(uint _value) public returns (uint256){

    require ( msg.sender == owner, "only owner");

    require ( OTRO_Contract.balanceOf(address(this)) >= _value, "The contract has no balance");

    OTRO_Contract.transfer(owner, _value);

    return _value;

  }

  function redimTRX() public returns (uint256){

    require ( msg.sender == owner, "only owner");

    require ( address(this).balance > 0, "The contract has no balance");

    owner.transfer( address(this).balance );

    return address(this).balance;

  }

  function redimTRX(uint _value) public returns (uint256){

    require ( msg.sender == owner, "only owner");

    require ( address(this).balance >= _value, "The contract has no balance");

    owner.transfer( _value);

    return _value;

  }

  function () external payable {}

}
