const Car = artifacts.require("./Car/RacersCar.sol");
const Part = artifacts.require("./Part/RacersPart.sol");

const RacersBoxFactory = artifacts.require("./RacersBoxFactory/RacersBoxFactory.sol");

const CarSaleAuction = artifacts.require("./CarSaleAuction/CarSaleAuction.sol");
const PartSaleAuction = artifacts.require("./PartSaleAuction/PartSaleAuction.sol");

const CarModding =   artifacts.require("./CarModding/CarModding.sol");
const TournamentAI = artifacts.require("./TournamentAI/TournamentAI.sol");


require('dotenv').config();
const delay = require('delay');

const paused = parseInt( process.env.DELAY_MS || "10" );

const wait = async (param) => { console.log("Delay " + paused); await delay(paused); return param;};
const logReceipt = (receipt, name) => console.log(name + " :: success :: " + receipt.tx);


const exchangeRateContract = process.env.EXCHANGE_RATE_CONTRACT;

if(!exchangeRateContract){
  throw("EXCHANGE_RATE_CONTRACT is not configured in .env!");
}

module.exports = function(deployer) {
  deployer.then(async () => {
    await wait();

    await wait(await deployer.deploy(Car));

    let car = await Car.deployed();
    await wait(logReceipt(await car.init(),
        'car.initialize'));


    await wait(await deployer.deploy(Part));

    let part = await Part.deployed();
    await wait(logReceipt(await part.init(),
        'part.initialize'));



    await wait(await deployer.deploy(RacersBoxFactory));

    let racersBoxFactory = await RacersBoxFactory.deployed();
    await wait(logReceipt(await racersBoxFactory.initialize( Car.address, Part.address ),
        'racersBoxFactory.initialize'));

    // clean up current discovery from everywhere
    await wait(logReceipt(await racersBoxFactory.setCarContract(car.address),
        "racersBoxFactory setCarContract car address " + car.address));

    await wait(logReceipt(await racersBoxFactory.setPartContract(part.address),
        "racersBoxFactory setPartContract part address " + part.address));

    await wait(logReceipt(await car.addAddressToWhitelist(racersBoxFactory.address),
        "car addAddressToWhitelist " + racersBoxFactory.address));

    await wait(logReceipt(await part.addAddressToWhitelist(racersBoxFactory.address),
        "part addAddressToWhitelist " + racersBoxFactory.address));

    const treasurerCommission = 500; // 5%

    await wait(await deployer.deploy(CarSaleAuction));

    let carSaleAuction = await CarSaleAuction.deployed();
    await wait(logReceipt(await carSaleAuction.init( car.address, treasurerCommission),
        'carSaleAuction.initialize'));

    await wait(logReceipt(await car.setCarSaleAuction(carSaleAuction.address),
        "car setCarSaleAuction " + carSaleAuction.address));

    await wait(logReceipt(await carSaleAuction.unpause(),
        "carSaleAuction unpause"));

    await wait(await deployer.deploy(PartSaleAuction));

    let partSaleAuction = await PartSaleAuction.deployed();
    await wait(logReceipt(await partSaleAuction.init( part.address, treasurerCommission),
        'partSaleAuction.initialize'));

    await wait(logReceipt(await part.setPartSaleAuction(partSaleAuction.address),
        "part setPartSaleAuction " + partSaleAuction.address));

    await wait(logReceipt(await partSaleAuction.unpause(),
        "partSaleAuction unpause"));

    await wait(await deployer.deploy(TournamentAI));

    let tournamentAI = await TournamentAI.deployed();
    await wait(logReceipt(await tournamentAI.init(),
        'tournamentAI.initialize'));

    await wait(await deployer.deploy(CarModding));

    let carModding = await CarModding.deployed();
    await wait(logReceipt(await carModding.initialize( Car.address ),
        'carModding.initialize'));

    await wait(logReceipt(await racersBoxFactory.setExchangeRateContract(exchangeRateContract),
        "racersBoxFactory setExchangeRateContract " + exchangeRateContract));

    await wait(logReceipt(await CarModding.setExchangeRateContract(exchangeRateContract),
        "CarModding setExchangeRateContract " + exchangeRateContract));
  });
};
