// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SectorTest } from "./SectorTest.sol";
import { IArrakisV2Factory } from "../src/interfaces/arrakis/IArrakisV2Factory.sol";
import { InitializePayload } from "../src/structs/SArrakisV2.sol";
import { IArrakisV2Helper } from "../src/interfaces/arrakis/IArrakisV2Helper.sol";
import { IArrakisV2Resolver } from "../src/interfaces/arrakis/IArrakisV2Resolver.sol";
import { IArrakisV2 } from "../src/interfaces/arrakis/IArrakisV2.sol";
import { ISwapRouter } from "../src/interfaces/uniswap/ISwapRouter.sol";
import { IUniswapV3Factory } from "../src/interfaces/uniswap/IUniswapV3Factory.sol";
import "forge-std/StdJson.sol";

import "hardhat/console.sol";

contract Setup is SectorTest {
	using stdJson for string;

	// GAS MEASUREMENTS
	string private checkpointLabel;
	uint256 private checkpointGasLeft = 1; // Start the slot warm.

	uint256 currentFork;

	IArrakisV2 mmVault;

	string pairName = "ArrakisMM_Y2K-ARB_arbitrum";

	address manager = address(101);
	address dao = user1;

	IERC20 token0;
	IERC20 token1;

	struct MMConfig {
		address baseToken;
		uint256 dec0;
		uint256 dec1;
		uint24 feeTier;
		string name;
		string symbol;
		address token0;
		address token1;
		string v_type;
		string x_chain;
	}

	// Arrakis configs
	IArrakisV2Factory arrakisFactory =
		IArrakisV2Factory(0xECb8Ffcb2369EF188A082a662F496126f66c8288);
	IArrakisV2Helper arrakisHelper = IArrakisV2Helper(0x07d2CeB4869DFE17e8D48c92A71eDC3AE564449f);
	IArrakisV2Resolver arrakisResolver =
		IArrakisV2Resolver(0xb11bb8ad710579Cc5ED16b1C8587808109c1f193);
	ISwapRouter uniV3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	IUniswapV3Factory uniV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

	function getConfig(string memory symbol) public returns (MMConfig memory _config) {
		string memory root = vm.projectRoot();
		string memory path = string.concat(root, "/config.json");
		string memory json = vm.readFile(path);
		bytes memory configBytes = json.parseRaw(string.concat(".", symbol));
		MMConfig memory _config = abi.decode(configBytes, (MMConfig));

		string memory RPC_URL = vm.envString(string.concat(_config.x_chain, "_RPC_URL"));
		uint256 BLOCK = vm.envUint(string.concat(_config.x_chain, "_BLOCK"));

		currentFork = vm.createFork(RPC_URL, BLOCK);
		vm.selectFork(currentFork);
		return _config;
	}

	function deployMMVault() public returns (IArrakisV2) {
		MMConfig memory config = getConfig(pairName);
		bool isBeacon_ = true;
		address[] memory routers = new address[](1);
		routers[0] = address(uniV3Router);
		uint24[] memory feeTiers = new uint24[](1);
		feeTiers[0] = config.feeTier;

		// ensure correct sort order:
		if (config.token0 > config.token1)
			(config.token0, config.token1) = (config.token1, config.token0);

		token0 = IERC20(config.token0);
		token1 = IERC20(config.token1);

		uint256 init0 = 1e18;
		uint256 init1 = 1e18;

		InitializePayload memory params_ = InitializePayload({
			feeTiers: feeTiers,
			token0: config.token0,
			token1: config.token1,
			owner: owner,
			init0: init0,
			init1: init1,
			manager: manager,
			routers: routers
		});

		address pool = uniV3Factory.getPool(config.token0, config.token1, feeTiers[0]);
		if (pool == address(0)) {
			uniV3Factory.createPool(config.token0, config.token1, feeTiers[0]);
		}

		return IArrakisV2(arrakisFactory.deployVault(params_, isBeacon_));
	}

	function setUp() public {
		mmVault = deployMMVault();
		mmVault.setRestrictedMint(dao);
	}

	function getMintAmnt(address token, uint256 amnt) public returns (uint256) {
		return amnt;
	}

	function startMeasuringGas(string memory label) internal virtual {
		checkpointLabel = label;

		checkpointGasLeft = gasleft();
	}

	function stopMeasuringGas() internal virtual {
		uint256 checkpointGasLeft2 = gasleft();

		// Subtract 100 to account for the warm SLOAD in startMeasuringGas.
		uint256 gasDelta = checkpointGasLeft - checkpointGasLeft2 - 100;

		emit log_named_uint(string(abi.encodePacked(checkpointLabel, " Gas")), gasDelta);
	}
}
