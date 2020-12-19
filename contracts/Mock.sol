pragma solidity ^0.4.23;

import "../Tools/Random.sol";
import "../Car/IRacersCar.sol";
import "../Access/TreasurerMigratable.sol";
import "../Access/WhitelistMigratable.sol";

contract RacersBoxFactory is TreasurerMigratable, Random, WhitelistMigratable {

    event NewBoxBought(address buyer, uint16 boxType);
    event BoxGifted(address sender, uint16 boxType);

    IRacersCar public car_;

    mapping (uint256 => uint256) public price;

    function initialize( address _carAddress) public isInitializer("RacersBoxFactory", "1.0.0") {
        require(_carAddress != address(0), "address incorrect");
        Ownable.initialize(msg.sender);

        transferTreasurer(owner);

        setCarContract(_carAddress);

        price[1] = 10000000; // car common
        price[2] = 20000000; // car plus
        price[3] = 40000000; // car pro
    }


    function setCarContract(address _carAddress) public onlyOwner {
        car_ = IRacersCar(_carAddress);
    }


    function buyBox (uint16 _boxType) public payable {
        require(msg.value >= price[_boxType], "Insufficient equity");

        _issue(msg.sender, _boxType);

        emit NewBoxBought(msg.sender, _boxType);
    }


    function giftBox (uint16 _boxType, address _to) public onlyWhitelisted {
        require(_to != address(0), "incorrect address, try again");
        _issue(_to, _boxType);

        emit BoxGifted(_to, _boxType);
    }


    function setBoxPrices(uint16 _type, uint256 _price) public onlyOwner {
        price[_type] = _price;
    }


    function getBoxPrices(uint256 _boxType) public view returns(uint256) {
        return price[_boxType];
    }

    function () public payable {
        revert();
    }


    function withdrawFactoryBalance() external onlyTreasurer {
        uint256 balance = address(this).balance;

        treasurer.transfer(balance);
    }


    function _issue(address _to, uint16 _boxType) internal view {
            uint256 randomCar;

            if (_boxType == 1) {
                car_.mintCar(_to, "CAR", _generateRarities( [750, 200, 48, 2]), _generateRandom(0,4));
            }
            if (_boxType == 2) {
                car_.mintCar(_to, "CAR", _generateRarities([450, 400, 140, 10]), _generateRandom(0,4));
            }
            if (_boxType == 3) {
                car_.mintCar(_to, "CAR", _generateRarities([100, 550, 300, 50]), _generateRandom(0,4));
            }
        }


    function _generateRarities ( uint16[4] memory _chances ) internal view returns ( uint8 ) {
        uint256 chance = _randRange(1,1000);

            if (chance <= _chances[0]) {
                return 0;
            }
            if (chance <= _chances[1]) {
                return 1;
            }
            if (chance <= _chances[2]) {
                return 2;
            }
            if (chance <= _chances[3]) {
                return 3;
            }
    }

    function _generateRandom(uint256 _begin, uint256 _end) internal view returns (uint8) {
        return uint8(_randRange(_begin, _end));
    }


    uint256[50] private ______gap;
}