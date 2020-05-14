pragma solidity ^0.4.21;

import "./ERC20.sol";
import "./Owned.sol";

contract FulcrumToken is ERC20, Owned {
    uint256 private tokenSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public fulcsPerWei;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;
    
    event Burn(address indexed from, uint256 value);
    
    event ExchangeInitiated(address contractAddress, address initiator);
    event ExchangeAccepted(address contractAddress, address partner);
    
    function FulcrumToken(uint256 _initialSupply, string _name, string _symbol, uint256 _fulcsPerWei) public {
        tokenSupply = _initialSupply * 10 ** uint256(decimals);    // total supply with the decimal amount
        balances[msg.sender] = tokenSupply;
        name = _name;
        symbol = _symbol;
        fulcsPerWei = _fulcsPerWei;
    }
    
    function totalSupply() public view returns (uint256) {
        return tokenSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);    // check for overflows
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndInitiateExchange(string _initiatorItemName, uint _initiatorItemQuantity,
                                        string _partnerItemName, uint _partnerItemQuantity, 
                                        uint _price, address _partner) public returns (bool) {
        Exchange exchangeContract = new Exchange(_initiatorItemName, _initiatorItemQuantity, _partnerItemName, _partnerItemQuantity, _price, msg.sender, _partner, this);
        if (approve(exchangeContract, _price)) {
            exchangeContract.initiate();
            emit ExchangeInitiated(exchangeContract, msg.sender);
            return true;
        }
        return false;
    }
    
    function approveAndAccept(Exchange _exchangeContract) public returns (bool) {
        if (approve(_exchangeContract, _exchangeContract.price())) {
            _exchangeContract.accept();
            emit ExchangeAccepted(_exchangeContract, msg.sender);
            return true;
        }
        return false;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    function burn(uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        tokenSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);
        require(_value <= allowances[_from][msg.sender]);
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        tokenSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    
    function setPrices(uint256 _fulcsPerWei) onlyOwner public {
        fulcsPerWei = _fulcsPerWei;
    }

    function buy() payable public {
        uint amount = msg.value * fulcsPerWei;
        if (msg.value == 0) {
            return;
        }
        require(amount / msg.value == fulcsPerWei);
        _transfer(this, msg.sender, amount);
    }
}
