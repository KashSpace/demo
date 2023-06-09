// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/protocol/KashPool.sol";
import "../src/protocol/KashCreditToken.sol";
import "../src/protocol/KashDebitToken.sol";
import "../src/protocol/lib/InterestRateModel.sol";
import "../src/protocol/lib/KashOracle.sol";
import { MToken } from "../src/protocol/cross/MToken.sol";
import "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

/**
 *
 * How To:
 * 1. Add envrioment variable at .env file.
 * 2. run: forge script script/KashPool.s.sol:KashScript -vvvv -s "initKashPool()" --fork-url $RPC_URL
 *
 */
contract KashScript is Script {
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
    }

    function initKashPool() external {
        vm.startBroadcast(deployerPrivateKey);
        KashOracle oracle = new KashOracle();
        InterestRateModel rateModel = new InterestRateModel();

        KashPool impl = new KashPool();

        ERC1967Proxy proxy = new ERC1967Proxy(
                    address(impl),
                    abi.encodeWithSelector(
                        KashPool.initialize.selector,
                        address(oracle)
                    )
                );

        console.log("KashPool address: ", address(proxy));
        console.log("KashPool oracle: ", address(oracle));
        console.log("KashPool rateModel: ", address(rateModel));

        vm.stopBroadcast();
    }

    function initAllAsset() external {
        address pool = 0x5310C07Cd8fc53bb47dDbFC8d86E1F0bcE213d17;
        address inter = 0x18655E1f7311f5D7B734636c38F2fe8EE09F3b82;
        vm.label(address(pool), "KashPool");

        createAsset(pool, inter, "kUSDT");
        createAsset(pool, inter, "kUSDC");
        createAsset(pool, inter, "kETH");
        createAsset(pool, inter, "kWBTC");
    }

    function createAsset(address pool, address inter, string memory symbol) public {
        address door = 0x8ADc0e2aFd67776df2F8946aA0649d8C19867C20;
        MToken token = new MToken(string.concat("Kash ",symbol),symbol,door);
        console.log(string.concat("Kash ", symbol), address(token));
        vm.label(address(token), symbol);

        createReserve(pool, inter, address(token));
    }

    function createReserve(address pool, address inter, address asset) public {
        KashPool pool = KashPool(pool);

        string memory symbol = IERC20Metadata(asset).symbol();
        uint8 decimal = IERC20Metadata(asset).decimals();

        KashCreditToken creditToken = new KashCreditToken(
          address(asset),
          string.concat( "Kash Credit ",symbol),
          string.concat( "c",symbol),
          decimal
        );

        KashDebitToken debitToken = new KashDebitToken(
          address(asset),
          string.concat( "Kash Debit ",symbol),
         string.concat(  "d",symbol),
          decimal
        );

        vm.label(address(debitToken), string.concat("d", symbol));
        vm.label(address(creditToken), string.concat("c", symbol));

        console.log(string.concat("d", symbol), address(debitToken));
        console.log(string.concat("c", symbol), address(creditToken));

        creditToken.setPool(address(pool));
        debitToken.setPool(address(pool));

        pool.initReserve(
            address(asset), address(creditToken), address(0), address(debitToken), address(inter)
        );
    }

    function setAssetPrice() external {
        address[] memory list = new address[](4);
        uint256[] memory prices = new uint256[](4);

        // USDT
        list[0] = 0xA0a121C77a3317Cf31B14b5a3089C2DAc70b5c3B; //USDT
        prices[0] = 1 * 1e18;

        list[1] = 0xFF8A1A10cFa544e9F1A77E121D4F393293A7Fa3E; //USDC
        prices[1] = 1 * 1e18;

        list[2] = 0xaBB9ADE0BC8C132d4F75c15538370E66A0734518; // ETH
        prices[2] = 1700 * 1e18;

        list[3] = 0xc44D60Da3ed467227C81BFAAC31b882880Cc13e8; // BTC
        prices[3] = 27000 * 1e18;

        KashOracle oracle = KashOracle(0xDdb2395921228Af6f49837a4acdc758E49065214);

        deployerPrivateKey = vm.envUint("RAW_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        oracle.batchSetPrice(list, prices);
        vm.stopBroadcast();
    }
}
