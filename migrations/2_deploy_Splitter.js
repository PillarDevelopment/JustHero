const PaymentSplitter = artifacts.require("./PaymentSplitter.sol");
const FIRST = TM76SgKaJVAjbWBkULWmh1GznVVL3mZZr3;
const SECOND = TEMewZTNKbA1w2bvEde4iejuLRLbXYdtFa;
const THIRD = TB7izYpX3rzf2R1PaLqhxYjeXCRekVQ2Z3;

const delay = require('delay');

const paused = parseInt( process.env.DELAY_MS || "20000" );

const wait = async (param) => { console.log("Delay " + paused); await delay(paused); return param;};

module.exports = function(deployer) {
    deployer.then(async () => {

        let splitterContract = await PaymentSplitter.deployed();
        await wait(logReceipt(await splitterContract.initialize( FIRST.address, SECOND.address, THIRD.address ),
            'splitterContract.initialize'));
    });
};