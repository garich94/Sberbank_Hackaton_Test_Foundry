//SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Factory} from "../src/Factory.sol";
import {Offer} from "../src/Offer.sol";

contract OfferTest is Test {
    Factory public factory;
    Offer public offer;
    address public landlord;
    address public ownerOffer = makeAddr("ownerOffer");
    address public tenant = makeAddr("tenant");
    address public notTenant = makeAddr("notTenant");

    event RenterMadeBat(
        address indexed renterAddr,
        uint256 indexed renterPrice,
        uint256 indexed renterDeposit
    );

    event RentedHousing(
        address indexed rented_by,
        uint256 indexed rentalPeriod,
        uint256 indexed rentalPrice
    );

    event RefundOfFund(
        address indexed refundAddr,
        uint256 indexed amountDeposit,
        uint256 indexed amountComission
    );

    function setUp() public {
        offer = new Offer(15, 10000, 100000);
        deal(tenant, 100 ether);
        deal(notTenant, 100 ether);
        landlord = offer.landlord();
    }

    function testRentRevertDeposit() public {
        // console.log(offer.landlord());
        // console.log(offer.owner());
        // console.log(offer.landlord().code.length);
        // console.log(offer.owner().code.length);

        // vm.prank(tenant);
        // offer.rent{value: 1000000}(100000, 1000000);
        vm.expectRevert(bytes("You have entered the wrong deposit amount."));
        vm.prank(tenant);
        offer.rent{value: 100000}(100000, 1000000);
    }

    function testRentRevertMinPrice() public {
        vm.expectRevert(
            bytes("Your price must be higher or equal to the minimum price.")
        );
        vm.prank(tenant);
        offer.rent{value: 10000}(1000, 10000);
    }

    function testRentRevertMinDeposit() public {
        vm.expectRevert(
            bytes("Your deposit must be above or equal to the minimum deposit.")
        );
        vm.prank(tenant);
        offer.rent{value: 10000}(10000, 10000);
    }

    function testRentOfferEmit() public {
        vm.expectEmit(true, true, true, true);

        emit RenterMadeBat(tenant, 10000, 100000);

        vm.prank(tenant);
        offer.rent{value: 100000}(10000, 100000);
    }

    function testRentRevertNotRented() public {
        vm.startPrank(tenant);
        offer.rent{value: 100000}(10000, 100000);
        vm.stopPrank();

        vm.startPrank(landlord);

        offer.approve(tenant);

        vm.stopPrank();

        vm.expectRevert(bytes("The apartment is already booked."));

        vm.startPrank(tenant);
        offer.rent{value: 100000}(10000, 100000);
    }

    function testApproveRevertNotLendlord() public {
        vm.expectRevert(bytes("Can only execute landlord."));
        vm.prank(tenant);
        offer.approve(tenant);
    }

    function testApproveRevertAddressZero() public {
        vm.expectRevert(bytes("you can't rent a place by yourself!"));
        vm.prank(landlord);
        offer.approve(address(0));
    }

    function testApproveExpectEmitRentedHousing() public {
        vm.startPrank(tenant);
        offer.rent{value: 100000}(10000, 100000);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit RentedHousing(tenant, block.timestamp + 30 days, 10000);

        vm.startPrank(landlord);

        offer.approve(tenant);
    }

    function testApproveExpectEmitRefundOfFund() public {
        vm.startPrank(tenant);
        offer.rent{value: 100000}(10000, 100000);
        vm.stopPrank();

        vm.startPrank(notTenant);
        offer.rent{value: 100000}(10000, 100000);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        uint comissionFactory = 100000 / 100;
        uint deposit = 100000 - comissionFactory;
        emit RefundOfFund(notTenant, deposit, comissionFactory);

        vm.startPrank(landlord);

        offer.approve(tenant);
    }

    function testCancelRevert() public {
        vm.expectRevert(
            bytes("your deposit is less than the established minimum.")
        );

        vm.prank(tenant);
        offer.cancel();
    }

    function testCancel() public {
        vm.startPrank(tenant);
        assertEq(tenant.balance, 100 ether);
        offer.rent{value: 10000000}(10000, 10000000);
        assertEq(tenant.balance, 100 ether - 10000000);

        offer.cancel();
        assertEq(tenant.balance, 100 ether);
    }

    function testCancelEmit() public {
        vm.startPrank(tenant);
        assertEq(tenant.balance, 100 ether);
        offer.rent{value: 10000000}(10000, 10000000);
        assertEq(tenant.balance, 100 ether - 10000000);

        vm.expectEmit(true, true, true, true);
        emit RefundOfFund(tenant, 10000000, 0);

        offer.cancel();
        assertEq(tenant.balance, 100 ether);
    }

    function testReRentRevertOnlyRenter() public {
        vm.prank(tenant);
        offer.rent{value: 10000000}(6000000, 10000000);
        vm.prank(landlord);
        offer.approve(tenant);

        vm.expectRevert(
            bytes("only the current tenant can call the function.")
        );
        vm.prank(notTenant);
        offer.reRent();
    }

    function testReRentReverSmallDeposit() public {
        vm.prank(tenant);
        offer.rent{value: 10000000}(6000000, 10000000);
        vm.prank(landlord);
        offer.approve(tenant);

        vm.expectRevert(
            bytes("there is not enough deposit for the next rental.")
        );
        vm.prank(tenant);
        offer.reRent();
    }

    function testReRentEmit() public {
        vm.prank(tenant);
        offer.rent{value: 10000000}(1000000, 10000000);

        vm.prank(landlord);
        offer.approve(tenant);
        uint rentedTill = offer.rented_till();

        vm.expectEmit(true, true, true, true);
        emit RentedHousing(tenant, rentedTill + 30 days, 1000000);

        vm.prank(tenant);
        offer.reRent();
    }

    function testBreakContractRevetDepositZero() public {
        vm.prank(tenant);
        offer.rent{value: 1010000}(1000000, 1010000);

        vm.prank(landlord);
        offer.approve(tenant);
        // console.log(offer.renternsInfoReturns(tenant));

        vm.expectRevert(bytes("your balance is zero!"));
        vm.prank(tenant);
        offer.break_contract();

        // assertEq(offer.rented_till(), 0);
        // assertEq(offer.rented_by(), address(0));
    }

    function testBreakContractEmit() public {
        vm.prank(tenant);
        offer.rent{value: 10000000}(1000000, 10000000);

        vm.prank(landlord);
        offer.approve(tenant);

        vm.expectEmit(true, true, true, true);
        emit RefundOfFund(tenant, offer.renternsInfoReturns(tenant), 0);

        vm.prank(tenant);
        offer.break_contract();

        assertEq(offer.rented_till(), 0);
        assertEq(offer.rented_by(), address(0));
    }

    function testReceive() public {
        vm.prank(tenant);
        payable(offer).transfer(1 ether);
    }

    receive() external payable {}
}
