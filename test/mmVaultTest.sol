// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import { Setup } from "./Setup.sol";

contract mmVaultTest is Setup {
	function testDeployment() public {
		uint256 t0Max = 100_000e18;
		uint256 t1Max = 100_000e18;
		(uint256 amount0, uint256 amount1, uint256 mintAmount) = arrakisResolver.getMintAmounts(
			mmVault,
			t0Max,
			t1Max
		);
		deal(address(token0), dao, amount0);
		deal(address(token1), dao, amount1);

		vm.startPrank(dao);

		token0.approve(address(mmVault), amount0);
		token1.approve(address(mmVault), amount1);

		mmVault.mint(mintAmount, dao);
		vm.stopPrank();

		assertEq(mmVault.balanceOf(dao), mintAmount);
	}
}
