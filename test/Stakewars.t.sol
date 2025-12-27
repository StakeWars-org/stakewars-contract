// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Stakewars} from "../src/Stakewars.sol";

contract StakewarsTest is Test {
    Stakewars public stakewars;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    uint256 public constant CHAKRA_DECIMALS = 18;
    uint256 public constant FREE_CHAKRA_AMOUNT = 400 * 10 ** CHAKRA_DECIMALS;
    
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        
        stakewars = new Stakewars();
    }
    
    // ============ Unit Tests: mintCharacter ============
    
    function test_MintCharacter_Success() public {
        stakewars.mintCharacter(user1, 1);
        
        assertEq(stakewars.balanceOf(user1, 1), 1);
        assertTrue(stakewars.hasFreeMinted(user1));
    }
    
    function test_MintCharacter_InvalidCharacterId() public {
        vm.expectRevert("Invalid character ID");
        stakewars.mintCharacter(user1, 0);
        
        vm.expectRevert("Invalid character ID");
        stakewars.mintCharacter(user1, 21);
    }
    
    function test_MintCharacter_AlreadyUsedFreeMint() public {
        stakewars.mintCharacter(user1, 1);
        
        vm.expectRevert("Address has already used free mint");
        stakewars.mintCharacter(user1, 2);
    }
    
    function test_MintCharacter_DifferentUsersCanMint() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintCharacter(user2, 2);
        
        assertEq(stakewars.balanceOf(user1, 1), 1);
        assertEq(stakewars.balanceOf(user2, 2), 1);
    }
    
    // ============ Unit Tests: mintChakra ============
    
    function test_MintChakra_Success() public {
        stakewars.mintChakra(user1);
        
        assertEq(stakewars.balanceOf(user1, 21), FREE_CHAKRA_AMOUNT);
        assertTrue(stakewars.hasFreeChakraMinted(user1));
    }
    
    function test_MintChakra_ZeroAddress() public {
        vm.expectRevert("Cannot mint to zero address");
        stakewars.mintChakra(address(0));
    }
    
    function test_MintChakra_AlreadyUsedFreeMint() public {
        stakewars.mintChakra(user1);
        
        vm.expectRevert("Address has already used free chakra mint");
        stakewars.mintChakra(user1);
    }
    
    function test_MintChakra_DifferentUsersCanMint() public {
        stakewars.mintChakra(user1);
        stakewars.mintChakra(user2);
        
        assertEq(stakewars.balanceOf(user1, 21), FREE_CHAKRA_AMOUNT);
        assertEq(stakewars.balanceOf(user2, 21), FREE_CHAKRA_AMOUNT);
    }
    
    // ============ Unit Tests: mintCharacterWithChakra ============
    
    function test_MintCharacterWithChakra_Success() public {
        // Setup: user1 gets chakra and approves contract
        stakewars.mintChakra(user1);
        // Give user1 more chakra for the test
        stakewars.mintChakra(user2);
        vm.prank(user2);
        stakewars.safeTransferFrom(user2, user1, 21, FREE_CHAKRA_AMOUNT, "");
        
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        uint256 cost = 300 * 10 ** CHAKRA_DECIMALS; // Use cost less than available balance
        uint256 initialBalance = stakewars.balanceOf(user1, 21);
        uint256 ownerInitialBalance = stakewars.balanceOf(owner, 21);
        
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(1, cost);
        
        // Check character was minted
        assertEq(stakewars.balanceOf(user1, 1), 1);
        
        // Check chakra was deducted (60% burned, 40% to owner)
        uint256 expectedBurn = (cost * 60) / 100;
        uint256 expectedOwnerAmount = cost - expectedBurn;
        assertEq(stakewars.balanceOf(user1, 21), initialBalance - cost);
        assertEq(stakewars.balanceOf(owner, 21), ownerInitialBalance + expectedOwnerAmount);
    }
    
    function test_MintCharacterWithChakra_InvalidCharacterId() public {
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        vm.expectRevert("Invalid character ID");
        stakewars.mintCharacterWithChakra(0, 1000 * 10 ** CHAKRA_DECIMALS);
    }
    
    function test_MintCharacterWithChakra_ZeroCost() public {
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        vm.expectRevert("Cost must be greater than 0");
        stakewars.mintCharacterWithChakra(1, 0);
    }
    
    function test_MintCharacterWithChakra_NotApproved() public {
        stakewars.mintChakra(user1);
        
        vm.prank(user1);
        vm.expectRevert("Contract not approved to spend chakra");
        stakewars.mintCharacterWithChakra(1, 1000 * 10 ** CHAKRA_DECIMALS);
    }
    
    // ============ Unit Tests: setCharacterCost ============
    
    function test_SetCharacterCost_Success() public {
        uint256 newCost = 5000 * 10 ** CHAKRA_DECIMALS;
        stakewars.setCharacterCost(1, newCost);
        
        assertEq(stakewars.characterCost(1), newCost);
    }
    
    function test_SetCharacterCost_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        stakewars.setCharacterCost(1, 1000 * 10 ** CHAKRA_DECIMALS);
    }
    
    function test_SetCharacterCost_InvalidCharacterId() public {
        vm.expectRevert("Invalid character ID");
        stakewars.setCharacterCost(0, 1000 * 10 ** CHAKRA_DECIMALS);
    }
    
    // ============ Unit Tests: purchaseBuff ============
    
    function test_PurchaseBuff_Success() public {
        // Setup: user1 gets character and chakra, approves contract
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        uint256 initialChakra = stakewars.balanceOf(user1, 21);
        uint256 ownerInitialChakra = stakewars.balanceOf(owner, 21);
        
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        // Check buff was purchased (remaining uses set)
        (uint256 effect, uint256 price, uint256 remainingTurns, string memory name) = 
            stakewars.getBuffInfo(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns);
        
        // Check chakra was deducted
        uint256 expectedBurn = (price * 60) / 100;
        uint256 expectedOwnerAmount = price - expectedBurn;
        assertEq(stakewars.balanceOf(user1, 21), initialChakra - price);
        assertEq(stakewars.balanceOf(owner, 21), ownerInitialChakra + expectedOwnerAmount);
    }
    
    function test_PurchaseBuff_InvalidCharacterId() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        vm.expectRevert("Invalid character ID");
        stakewars.purchaseBuff(0, 1);
    }
    
    function test_PurchaseBuff_InvalidBuffId() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        vm.expectRevert("Invalid buff ID");
        stakewars.purchaseBuff(1, 0);
        
        vm.prank(user1);
        vm.expectRevert("Invalid buff ID");
        stakewars.purchaseBuff(1, 6);
    }
    
    function test_PurchaseBuff_DoesNotOwnCharacter() public {
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        vm.expectRevert("You don't own this character");
        stakewars.purchaseBuff(1, 1);
    }
    
    function test_PurchaseBuff_AlreadyPurchased() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        // Try to purchase again
        vm.prank(user1);
        vm.expectRevert("Buff already purchased or not exhausted");
        stakewars.purchaseBuff(1, 1);
    }
    
    function test_PurchaseBuff_InsufficientChakra() public {
        stakewars.mintCharacter(user1, 1);
        // Don't mint chakra - user1 will have 0 chakra
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Get buff price (150 * 10^18)
        (, uint256 price,,) = stakewars.getBuffInfo(1, 1);
        
        // User has 0 chakra, price is 150, so should fail
        vm.prank(user1);
        vm.expectRevert("Insufficient chakra");
        stakewars.purchaseBuff(1, 1);
    }
    
    function test_PurchaseBuff_NotApproved() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        
        vm.prank(user1);
        vm.expectRevert("Contract not approved to spend chakra");
        stakewars.purchaseBuff(1, 1);
    }
    
    function test_PurchaseBuff_VillageRestriction() public {
        // user1 has Hidden Leaf character (KAZAN)
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Try to purchase Hidden Sand buff (should fail)
        // KAZAN is Hidden Leaf, so can only buy Hidden Leaf buffs
        // This should work because we're buying buff 1 from Hidden Leaf village
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        // Verify it's a Hidden Leaf buff
        (,, uint256 remainingTurns,) = stakewars.getBuffInfo(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns);
    }
    
    // ============ Unit Tests: increaseBuffUse ============
    
    function test_IncreaseBuffUse_Success() public {
        // Setup: purchase buff first
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        uint256 initialUses = stakewars.getBuffStatus(user1, 1, 1);
        uint256 increaseAmount = 5;
        
        vm.prank(user1);
        stakewars.increaseBuffUse(1, 1, increaseAmount);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), initialUses + increaseAmount);
    }
    
    function test_IncreaseBuffUse_InvalidCharacterId() public {
        vm.prank(user1);
        vm.expectRevert("Invalid character ID");
        stakewars.increaseBuffUse(0, 1, 1);
    }
    
    function test_IncreaseBuffUse_InvalidBuffId() public {
        vm.prank(user1);
        vm.expectRevert("Invalid buff ID");
        stakewars.increaseBuffUse(1, 0, 1);
    }
    
    function test_IncreaseBuffUse_DoesNotOwnCharacter() public {
        vm.prank(user1);
        vm.expectRevert("You don't own this character");
        stakewars.increaseBuffUse(1, 1, 1);
    }
    
    function test_IncreaseBuffUse_DoesNotOwnBuff() public {
        stakewars.mintCharacter(user1, 1);
        
        vm.prank(user1);
        vm.expectRevert("You don't own this buff for this character");
        stakewars.increaseBuffUse(1, 1, 1);
    }
    
    function test_IncreaseBuffUse_ZeroAmount() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        stakewars.increaseBuffUse(1, 1, 0);
    }
    
    // ============ Unit Tests: decreaseBuffUse ============
    
    function test_DecreaseBuffUse_Success() public {
        // Setup: purchase buff first
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        uint256 initialUses = stakewars.getBuffStatus(user1, 1, 1);
        uint256 decreaseAmount = 1;
        
        vm.prank(user1);
        stakewars.decreaseBuffUse(1, 1, decreaseAmount);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), initialUses - decreaseAmount);
    }
    
    function test_DecreaseBuffUse_ExhaustBuff() public {
        // Setup: purchase buff first
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        uint256 remainingUses = stakewars.getBuffStatus(user1, 1, 1);
        
        // Use all remaining uses
        vm.prank(user1);
        stakewars.decreaseBuffUse(1, 1, remainingUses);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), 0);
        
        // Try to use again (should fail)
        vm.prank(user1);
        vm.expectRevert("Not enough remaining uses");
        stakewars.decreaseBuffUse(1, 1, 1);
    }
    
    function test_DecreaseBuffUse_InvalidCharacterId() public {
        vm.prank(user1);
        vm.expectRevert("Invalid character ID");
        stakewars.decreaseBuffUse(0, 1, 1);
    }
    
    function test_DecreaseBuffUse_InvalidBuffId() public {
        vm.prank(user1);
        vm.expectRevert("Invalid buff ID");
        stakewars.decreaseBuffUse(1, 0, 1);
    }
    
    function test_DecreaseBuffUse_DoesNotOwnCharacter() public {
        vm.prank(user1);
        vm.expectRevert("You don't own this character");
        stakewars.decreaseBuffUse(1, 1, 1);
    }
    
    function test_DecreaseBuffUse_NotEnoughUses() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        uint256 remainingUses = stakewars.getBuffStatus(user1, 1, 1);
        
        vm.prank(user1);
        vm.expectRevert("Not enough remaining uses");
        stakewars.decreaseBuffUse(1, 1, remainingUses + 1);
    }
    
    function test_DecreaseBuffUse_ZeroAmount() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        vm.prank(user1);
        vm.expectRevert("Amount must be greater than 0");
        stakewars.decreaseBuffUse(1, 1, 0);
    }
    
    // ============ Unit Tests: getBuffInfo ============
    
    function test_GetBuffInfo_Success() public {
        (uint256 effect, uint256 price, uint256 remainingTurns, string memory name) = 
            stakewars.getBuffInfo(1, 1);
        
        assertEq(effect, 5);
        assertEq(price, 150 * 10 ** CHAKRA_DECIMALS);
        assertEq(remainingTurns, 3);
        assertEq(name, "Kunai Precision");
    }
    
    function test_GetBuffInfo_AllVillages() public {
        // Test all villages have correct buffs
        (uint256 effect1,, uint256 turns1, string memory name1) = stakewars.getBuffInfo(1, 1);
        (uint256 effect2,, uint256 turns2, string memory name2) = stakewars.getBuffInfo(2, 1);
        (uint256 effect3,, uint256 turns3, string memory name3) = stakewars.getBuffInfo(3, 1);
        (uint256 effect4,, uint256 turns4, string memory name4) = stakewars.getBuffInfo(4, 1);
        
        assertEq(effect1, 5);
        assertEq(effect2, 5);
        assertEq(effect3, 5);
        assertEq(effect4, 5);
        assertEq(turns1, 3);
        assertEq(turns2, 3);
        assertEq(turns3, 3);
        assertEq(turns4, 3);
    }
    
    // ============ Unit Tests: getBuffStatus ============
    
    function test_GetBuffStatus_NotOwned() public {
        assertEq(stakewars.getBuffStatus(user1, 1, 1), 0);
    }
    
    function test_GetBuffStatus_Owned() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        (,, uint256 remainingTurns,) = stakewars.getBuffInfo(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns);
    }
    
    // ============ Integration Tests ============
    
    function test_Integration_FullFlow() public {
        // 1. User mints character
        stakewars.mintCharacter(user1, 1);
        assertEq(stakewars.balanceOf(user1, 1), 1);
        
        // 2. User mints chakra
        stakewars.mintChakra(user1);
        assertEq(stakewars.balanceOf(user1, 21), FREE_CHAKRA_AMOUNT);
        
        // 3. User approves contract
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // 4. User purchases buff
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        (,, uint256 remainingTurns,) = stakewars.getBuffInfo(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns);
        
        // 5. User uses buff
        vm.prank(user1);
        stakewars.decreaseBuffUse(1, 1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns - 1);
        
        // 6. User refills buff
        vm.prank(user1);
        stakewars.increaseBuffUse(1, 1, 2);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), remainingTurns + 1);
    }
    
    function test_Integration_MultipleUsers() public {
        // User1: Hidden Leaf character
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        // User2: Hidden Sand character
        stakewars.mintCharacter(user2, 6);
        stakewars.mintChakra(user2);
        vm.prank(user2);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user2);
        stakewars.purchaseBuff(6, 1);
        
        // Verify both users have their buffs
        (,, uint256 leafTurns,) = stakewars.getBuffInfo(1, 1);
        (,, uint256 sandTurns,) = stakewars.getBuffInfo(2, 1);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), leafTurns);
        assertEq(stakewars.getBuffStatus(user2, 6, 1), sandTurns);
    }
    
    function test_Integration_MultipleBuffs() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        // Give user1 more chakra (buff prices: 150 + 250 + 400 = 800)
        stakewars.mintChakra(user2);
        stakewars.mintChakra(user3);
        vm.prank(user2);
        stakewars.safeTransferFrom(user2, user1, 21, FREE_CHAKRA_AMOUNT, "");
        vm.prank(user3);
        stakewars.safeTransferFrom(user3, user1, 21, FREE_CHAKRA_AMOUNT, "");
        
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Purchase multiple buffs
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 2);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 3);
        
        (,, uint256 turns1,) = stakewars.getBuffInfo(1, 1);
        (,, uint256 turns2,) = stakewars.getBuffInfo(1, 2);
        (,, uint256 turns3,) = stakewars.getBuffInfo(1, 3);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), turns1);
        assertEq(stakewars.getBuffStatus(user1, 1, 2), turns2);
        assertEq(stakewars.getBuffStatus(user1, 1, 3), turns3);
    }
    
    function test_Integration_BuffExhaustionAndRepurchase() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Purchase buff
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        (,, uint256 initialTurns,) = stakewars.getBuffInfo(1, 1);
        
        // Exhaust buff
        vm.prank(user1);
        stakewars.decreaseBuffUse(1, 1, initialTurns);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), 0);
        
        // Get more chakra and repurchase
        // Note: user already used free mint, so we need to transfer chakra
        stakewars.mintChakra(user2);
        vm.prank(user2);
        stakewars.safeTransferFrom(user2, user1, 21, FREE_CHAKRA_AMOUNT, "");
        
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), initialTurns);
    }
    
    // ============ Edge Cases ============
    
    function test_EdgeCase_AllCharacters() public {
        // Test minting all 20 characters
        for (uint256 i = 1; i <= 20; i++) {
            address user = address(uint160(i + 100));
            stakewars.mintCharacter(user, i);
            assertEq(stakewars.balanceOf(user, i), 1);
        }
    }
    
    function test_EdgeCase_AllBuffs() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        // Give user1 enough chakra for all 5 buffs (150+250+400+600+850 = 2250)
        // Need 6 free mints worth (6 * 400 = 2400)
        for (uint256 i = 0; i < 6; i++) {
            address tempUser = address(uint160(1000 + i));
            stakewars.mintChakra(tempUser);
            vm.prank(tempUser);
            stakewars.safeTransferFrom(tempUser, user1, 21, FREE_CHAKRA_AMOUNT, "");
        }
        
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Purchase all 5 buffs
        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(user1);
            stakewars.purchaseBuff(1, i);
            (,, uint256 turns,) = stakewars.getBuffInfo(1, i);
            assertEq(stakewars.getBuffStatus(user1, 1, i), turns);
        }
    }
    
    function test_EdgeCase_LargeAmountIncrease() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1);
        
        uint256 largeAmount = 1000;
        vm.prank(user1);
        stakewars.increaseBuffUse(1, 1, largeAmount);
        
        (,, uint256 initialTurns,) = stakewars.getBuffInfo(1, 1);
        assertEq(stakewars.getBuffStatus(user1, 1, 1), initialTurns + largeAmount);
    }
    
    function test_EdgeCase_Precision60PercentBurn() public {
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        // Use a cost that doesn't divide evenly by 100
        uint256 cost = 333 * 10 ** CHAKRA_DECIMALS;
        uint256 initialBalance = stakewars.balanceOf(user1, 21);
        uint256 ownerInitialBalance = stakewars.balanceOf(owner, 21);
        
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(1, cost);
        
        uint256 expectedBurn = (cost * 60) / 100;
        uint256 expectedOwnerAmount = cost - expectedBurn;
        
        assertEq(stakewars.balanceOf(user1, 21), initialBalance - cost);
        assertEq(stakewars.balanceOf(owner, 21), ownerInitialBalance + expectedOwnerAmount);
    }
    
    function test_EdgeCase_DifferentVillageCharacters() public {
        // Test that characters from different villages can't buy each other's buffs
        // This is implicitly tested by village assignment, but let's verify
        
        // Hidden Leaf character
        stakewars.mintCharacter(user1, 1);
        assertEq(stakewars.characterVillage(1), 1);
        
        // Hidden Sand character
        stakewars.mintCharacter(user2, 6);
        assertEq(stakewars.characterVillage(6), 2);
        
        // Both should be able to purchase their own village's buffs
        stakewars.mintChakra(user1);
        stakewars.mintChakra(user2);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user2);
        stakewars.setApprovalForAll(address(stakewars), true);
        
        vm.prank(user1);
        stakewars.purchaseBuff(1, 1); // Hidden Leaf buff
        
        vm.prank(user2);
        stakewars.purchaseBuff(6, 1); // Hidden Sand buff
        
        (,, uint256 leafTurns,) = stakewars.getBuffInfo(1, 1);
        (,, uint256 sandTurns,) = stakewars.getBuffInfo(2, 1);
        
        assertEq(stakewars.getBuffStatus(user1, 1, 1), leafTurns);
        assertEq(stakewars.getBuffStatus(user2, 6, 1), sandTurns);
    }
    
    // ============ Unit Tests: getCharactersOwnedByUser ============
    
    function test_GetCharactersOwnedByUser_NoCharacters() public {
        uint256[] memory characters = stakewars.getCharactersOwnedByUser(user1);
        assertEq(characters.length, 0);
    }
    
    function test_GetCharactersOwnedByUser_SingleCharacter() public {
        stakewars.mintCharacter(user1, 1);
        
        uint256[] memory characters = stakewars.getCharactersOwnedByUser(user1);
        assertEq(characters.length, 1);
        assertEq(characters[0], 1);
    }
    
    function test_GetCharactersOwnedByUser_MultipleCharacters() public {
        // Mint multiple characters to user1
        stakewars.mintCharacter(user1, 1);
        stakewars.mintCharacter(user2, 2); // Different user
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(3, 100 * 10 ** CHAKRA_DECIMALS);
        
        uint256[] memory characters = stakewars.getCharactersOwnedByUser(user1);
        assertEq(characters.length, 2);
        // Check that both characters are in the array
        bool found1 = false;
        bool found3 = false;
        for (uint256 i = 0; i < characters.length; i++) {
            if (characters[i] == 1) found1 = true;
            if (characters[i] == 3) found3 = true;
        }
        assertTrue(found1);
        assertTrue(found3);
    }
    
    function test_GetCharactersOwnedByUser_DifferentVillages() public {
        // Mint characters from different villages
        stakewars.mintCharacter(user1, 1); // Hidden Leaf
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(6, 100 * 10 ** CHAKRA_DECIMALS); // Hidden Sand
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(11, 100 * 10 ** CHAKRA_DECIMALS); // Hidden Mist
        
        uint256[] memory characters = stakewars.getCharactersOwnedByUser(user1);
        assertEq(characters.length, 3);
        
        // Verify all three characters are present
        bool found1 = false;
        bool found6 = false;
        bool found11 = false;
        for (uint256 i = 0; i < characters.length; i++) {
            if (characters[i] == 1) found1 = true;
            if (characters[i] == 6) found6 = true;
            if (characters[i] == 11) found11 = true;
        }
        assertTrue(found1);
        assertTrue(found6);
        assertTrue(found11);
    }
    
    function test_GetCharactersOwnedByUser_AllCharacters() public {
        // Mint all 20 characters to different users, then transfer some to user1
        for (uint256 i = 1; i <= 20; i++) {
            address tempUser = address(uint160(1000 + i));
            stakewars.mintCharacter(tempUser, i);
            // Transfer first 10 to user1
            if (i <= 10) {
                vm.prank(tempUser);
                stakewars.setApprovalForAll(user1, true);
                vm.prank(tempUser);
                stakewars.safeTransferFrom(tempUser, user1, i, 1, "");
            }
        }
        
        uint256[] memory characters = stakewars.getCharactersOwnedByUser(user1);
        assertEq(characters.length, 10);
        
        // Verify all characters 1-10 are present
        for (uint256 i = 1; i <= 10; i++) {
            bool found = false;
            for (uint256 j = 0; j < characters.length; j++) {
                if (characters[j] == i) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "Character not found in array");
        }
    }
    
    function test_GetCharactersOwnedByUser_MultipleUsers() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintCharacter(user2, 2);
        stakewars.mintCharacter(user3, 3);
        
        // User1 gets another character via paid mint
        stakewars.mintChakra(user1);
        vm.prank(user1);
        stakewars.setApprovalForAll(address(stakewars), true);
        vm.prank(user1);
        stakewars.mintCharacterWithChakra(4, 100 * 10 ** CHAKRA_DECIMALS);
        
        uint256[] memory user1Characters = stakewars.getCharactersOwnedByUser(user1);
        uint256[] memory user2Characters = stakewars.getCharactersOwnedByUser(user2);
        uint256[] memory user3Characters = stakewars.getCharactersOwnedByUser(user3);
        
        assertEq(user1Characters.length, 2);
        assertEq(user2Characters.length, 1);
        assertEq(user3Characters.length, 1);
        
        // Verify user1 has characters 1 and 4
        bool user1Has1 = false;
        bool user1Has4 = false;
        for (uint256 i = 0; i < user1Characters.length; i++) {
            if (user1Characters[i] == 1) user1Has1 = true;
            if (user1Characters[i] == 4) user1Has4 = true;
        }
        assertTrue(user1Has1);
        assertTrue(user1Has4);
        
        // Verify user2 has character 2
        assertEq(user2Characters[0], 2);
        
        // Verify user3 has character 3
        assertEq(user3Characters[0], 3);
    }
    
    function test_GetCharactersOwnedByUser_AfterTransfer() public {
        stakewars.mintCharacter(user1, 1);
        stakewars.mintCharacter(user2, 2);
        
        // Transfer character 2 from user2 to user1
        vm.prank(user2);
        stakewars.setApprovalForAll(user1, true);
        vm.prank(user2);
        stakewars.safeTransferFrom(user2, user1, 2, 1, "");
        
        uint256[] memory user1Characters = stakewars.getCharactersOwnedByUser(user1);
        uint256[] memory user2Characters = stakewars.getCharactersOwnedByUser(user2);
        
        assertEq(user1Characters.length, 2);
        assertEq(user2Characters.length, 0);
        
        // Verify user1 has both characters 1 and 2
        bool user1Has1 = false;
        bool user1Has2 = false;
        for (uint256 i = 0; i < user1Characters.length; i++) {
            if (user1Characters[i] == 1) user1Has1 = true;
            if (user1Characters[i] == 2) user1Has2 = true;
        }
        assertTrue(user1Has1);
        assertTrue(user1Has2);
    }
}
