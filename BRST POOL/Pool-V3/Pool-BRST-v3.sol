 pragma solidity >=0.8.0;
// SPDX-License-Identifier: Apache-2.0

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface TRC20_Interface {

  function allowance(address _owner, address _spender) external view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _value) external returns (bool);
  function transfer(address direccion, uint cantidad) external returns (bool);
  function balanceOf(address who) external view returns (uint256);
  function decimals() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function issue(uint amount) external;
  function redeem(uint amount) external;
  function transferOwnership(address newOwner) external;

}

contract PoolBRSTv3 is Ownable{
  using SafeMath for uint;

  TRC20_Interface BRTS_Contract = TRC20_Interface(0x389ccc30de1d311738Dffd3F60D4fD6188970F45);

  TRC20_Interface OTRO_Contract = TRC20_Interface(0x389ccc30de1d311738Dffd3F60D4fD6188970F45);

  struct Usuario {
    uint[] id;
    bool[] completado; 
    uint256[] tiempo;
    uint256[] trxx;
    uint256[] brst;
    address[] partner;

  }

  uint public MIN_DEPOSIT = 1 * 10**6;
  uint public TRON_GANANCIAS = 0;
  uint public TRON_SOLICITADO = 0;

  uint public TRON_WALLET_BALANCE;

  uint public dias_de_pago = 15;
  uint public unidades_tiempo = 86400;

  address public NoValido = address(0);

  mapping (address => Usuario) private usuarios;
  mapping (uint => address ) public solicitudesEnProgreso;
  mapping (uint => uint ) public solicitudInterna;

  uint public index = 0;

  constructor(uint _cantidadTRX) {
    TRON_WALLET_BALANCE = _cantidadTRX;
  }

  function TRON_TOTAL_BALANCE() public view returns (uint){
      return TRON_PAY_BALANCE().add(TRON_WALLET_BALANCE).add(TRON_GANANCIAS);
  }

  function TRON_BALANCE() public view returns (uint){
      return TRON_WALLET_BALANCE.add(TRON_GANANCIAS);
  }

  function TRON_PAY_BALANCE() public view returns (uint){
    return address(this).balance;
  }

  function RATE() public view returns (uint){
    //1 BRST -> TRX
    return (TRON_BALANCE().mul(10**BRTS_Contract.decimals())).div( BRTS_Contract.totalSupply() );

  }

  function TIEMPO() public view returns (uint){

    return dias_de_pago.mul(unidades_tiempo);

  }

  function setDias(uint _dias) public onlyOwner returns (bool){

    dias_de_pago = _dias;

    return true;

  }

  function setUnidadesTiempo(uint _unidades) public onlyOwner returns (bool){

    unidades_tiempo = _unidades;

    return true;

  }

  function ChangeToken(address _tokenTRC20) public onlyOwner returns (bool){

    BRTS_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }

  function ChangeTokenOTRO(address _tokenTRC20) public onlyOwner returns (bool){

    OTRO_Contract = TRC20_Interface(_tokenTRC20);

    return true;

  }

  function newOwnerBRTS(address _newowner) public onlyOwner returns (bool){

    BRTS_Contract.transferOwnership(_newowner);

    return true;

  }

  function solicitudRetiro(uint256 _value) public returns (uint256){

    if( BRTS_Contract.allowance(msg.sender, address(this)) < _value || BRTS_Contract.balanceOf(msg.sender) < _value)revert();

    uint pago = _value.mul(RATE()).div(10 ** BRTS_Contract.decimals());
    
    if( !BRTS_Contract.transferFrom(msg.sender, address(this), _value) )revert();

    Usuario storage usuario = usuarios[msg.sender];

    usuario.id.push(index);
    usuario.completado.push(false);
    usuario.tiempo.push(block.timestamp);
    usuario.trxx.push(pago);
    usuario.brst.push(_value);
    usuario.partner.push(address(0));

    TRON_SOLICITADO += pago;

    solicitudesEnProgreso[index] = msg.sender;
    solicitudInterna[index] = usuario.id.length-1;
    index++;

    return pago;

  }

  function retirar(uint256 _id) public {

    Usuario storage usuario = usuarios[msg.sender];

    if( _id >= largoSolicitudes(msg.sender) || block.timestamp < usuario.tiempo[_id].add(TIEMPO()) || usuario.completado[_id] )revert();

    uint pago = usuario.trxx[_id];

    if(TRON_PAY_BALANCE() < pago)revert();
    payable(msg.sender).transfer(pago);
    BRTS_Contract.redeem(usuario.brst[_id]);
    usuario.completado[_id] = true;

    TRON_WALLET_BALANCE -= pago;
    TRON_SOLICITADO -= pago;

  }

  function largoSolicitudes(address _user) public view returns(uint256){

    Usuario storage usuario = usuarios[_user];

    return usuario.trxx.length ;

  }

  function todasSolicitudes(address _user) public view returns(uint[] memory id, uint256[] memory tiempo, uint256[] memory trxx, uint256[] memory brst, bool[] memory completado, address[] memory partner){

    Usuario storage usuario = usuarios[_user];

    return (usuario.id, usuario.tiempo, usuario.trxx, usuario.brst, usuario.completado, usuario.partner);
  }


  function solicitudesPendientesGlobales() public view returns(uint256[] memory ){

    uint256[] memory pGlobales;
    uint256 a;
    address _user;
    Usuario storage usuario;
    
    for (uint i = 0 ; i < index; i++) {

      _user = solicitudesEnProgreso[i];

      usuario = usuarios[_user];

      if(!usuario.completado[solicitudInterna[i]]){
        pGlobales = actualizarArray(pGlobales);
        pGlobales[a] = i;
        a++;
      }
      
    }
    
    return (pGlobales);

  }

  function actualizarArray(uint256[] memory oldArray)public pure returns ( uint256[] memory) {
    uint256[] memory newArray = new uint256[](oldArray.length+1);

    for(uint i = 0; i < oldArray.length; i++){
        newArray[i] = oldArray[i];
    }
    
    return newArray;
  }

  function verSolicitudPendiente(uint256 _id) public view returns(bool, uint, uint, uint, address){

    address _user = solicitudesEnProgreso[_id];
    Usuario storage usuario = usuarios[_user];

    return (
      usuario.completado[solicitudInterna[_id]],
      usuario.tiempo[solicitudInterna[_id]],
      usuario.trxx[solicitudInterna[_id]],
      usuario.brst[solicitudInterna[_id]],
      usuario.partner[solicitudInterna[_id]]
    );


  }

  function completarSolicitud(uint256 _index) public payable returns (bool){

    address payable _user = payable(solicitudesEnProgreso[_index]);
    uint _id = solicitudInterna[_index];
    Usuario storage usuario = usuarios[_user];

    if(usuario.completado[_id])revert();

    if(msg.sender != _user){
      if(msg.value != usuario.trxx[_id])revert();
      _user.transfer(usuario.trxx[_id]);
    }else{
      _user.transfer(msg.value);
    }

    BRTS_Contract.transfer(msg.sender, usuario.brst[_id]);
    usuario.partner[_id] = msg.sender;
    usuario.completado[_id] = true;

    TRON_SOLICITADO -= usuario.trxx[_id];

    return true;

  }

  function staking() public payable returns (uint) {

    if(msg.value < MIN_DEPOSIT)revert();
    uint _value = msg.value;
      
    payable(owner).transfer(_value);

    _value = (_value.mul( 10 ** BRTS_Contract.decimals() )).div(RATE());
    TRON_WALLET_BALANCE += msg.value;

    BRTS_Contract.issue(_value);

    BRTS_Contract.transfer(msg.sender,_value);

    return _value;

  }

  function asignarGanacia(uint _value) public onlyOwner returns(uint){

    TRON_GANANCIAS += _value;

    return _value;

  }

  function pagarGanacias() public onlyOwner returns(uint){

    TRON_WALLET_BALANCE += TRON_GANANCIAS;
    TRON_GANANCIAS = 0;

    return TRON_WALLET_BALANCE;

  }

  function restarGanacia(uint _value) public onlyOwner returns(uint){

    TRON_GANANCIAS -= _value;
    return _value;

  }

  function asignarPerdida(uint _value) public onlyOwner returns(uint){

    TRON_WALLET_BALANCE -= _value;

    return _value;

  }

  function gananciaDirecta(uint _value) public onlyOwner returns(uint){

    TRON_WALLET_BALANCE += _value;

    return _value;

  }

  function crearBRTS(uint _value) public onlyOwner returns(bool){
    BRTS_Contract.issue(_value);
    BRTS_Contract.transfer(owner, _value);

    return true;
      
  }

  function quemarBRTS(uint _value) public onlyOwner returns(bool, uint256){

    if( BRTS_Contract.allowance(msg.sender, address(this)) < _value || 
    BRTS_Contract.balanceOf(msg.sender) < _value ||
    !BRTS_Contract.transferFrom(msg.sender, address(this), _value))revert();
      
    BRTS_Contract.redeem(_value);

    return (true,_value);
      
  }

  function redimBRTS01() public onlyOwner returns (uint256){

    uint256 valor = BRTS_Contract.balanceOf(address(this));

    BRTS_Contract.transfer(owner, valor);

    return valor;
  }

  function redimBRTS02(uint _value) public onlyOwner returns (uint256) {

    if ( BRTS_Contract.balanceOf(address(this)) < _value)revert();

    BRTS_Contract.transfer(owner, _value);

    return _value;

  }

  function redimOTRO01() public onlyOwner returns (uint256){

    uint256 valor = OTRO_Contract.balanceOf(address(this));

    OTRO_Contract.transfer(owner, valor);

    return valor;
  }

  function redimTRX() public onlyOwner returns (uint256){

    if ( address(this).balance == 0)revert();

    payable(owner).transfer( address(this).balance );

    return address(this).balance;

  }

  function redimTRX(uint _value) public onlyOwner returns (uint256){

    if ( address(this).balance < _value)revert();

    payable(owner).transfer( _value);

    return _value;

  }

  fallback() external payable {}

  receive() external payable {}

}