// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICrunchApp.sol";
import "./ICrunchSpace.sol";

// @creator yanghao@ohdat.io
contract CrunchApp is Ownable {
    address _spaceAddress;
    uint256 _tokenID;
    uint256 _price;
    mapping(address => address) _invater;
    uint256 _totalSales;
    mapping(address => uint256) _userSales;

    constructor(
        address initialOwner,
        address spaceAddress,
        uint256 tokenID
    ) Ownable(initialOwner) {
        _spaceAddress = spaceAddress;
        _tokenID = tokenID;
    }

    function dappID() public view returns (uint256) {
        return _tokenID;
    }

    function creator() public view returns (address) {
        return owner();
    }

    function setPrice(uint256 price_) public onlyOwner {
        _price = price_;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function recharege(address invater_, uint256 amount) public payable {
        require(msg.value == _price * amount, "price not match");
        if (_invater[invater_] == address(0)) {
            _invater[invater_] = msg.sender;
        }
        // 三层分润
        uint256[] memory rates = ICrunchSpace(_spaceAddress)
            .getCommissionRate();
        uint256 rechargeValue_ = msg.value;
        for (uint256 i = 0; i < rates.length; i++) {
            address invater = _invater[invater_];
            if (invater == address(0)) {
                break;
            }
            uint256 commission = (amount * rates[i]) / 100;
            payable(invater).transfer(commission);
            rechargeValue_ -= commission;
            // ICrunchSpace(_spaceAddress).recharge{value: commission}(invater, amount);
            invater_ = invater;
        }
        _userSales[msg.sender] += amount;
        _totalSales += amount;
        ICrunchSpace(_spaceAddress).recharge{value: rechargeValue_}(_tokenID);
    }
}
