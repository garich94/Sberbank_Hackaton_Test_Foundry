//SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Factory} from "../src/Factory.sol";

contract FactoryTest is Test {
    Factory public factory;
    //address public newOffer;
    address public ownerOffer = makeAddr("owner");

    event CreateNewOffer(
        address indexed addrNewOffer,
        uint256 indexed min_price,
        uint256 indexed min_deposit
    );

    function setUp() public {
        factory = new Factory();
        vm.prank(ownerOffer);
        factory.create_offer(15, 100, 1000);
    }

    function testCreate_OfferCallSmartContract() public {
        vm.expectRevert(bytes("The landlord cannot be a smart contract!"));
        factory.create_offer(14, 1000, 10000);
    }

    function testCreate_OfferCallAddressZero() public {
        vm.expectRevert(bytes("An object with this id already exists!"));

        vm.prank(makeAddr("owner"));
        factory.create_offer(15, 100, 1000);
    }

    function testCreate_OfferEmit() public {
        vm.expectEmit(false, true, true, true);

        uint min_price = 100;
        uint min_deposit = 1000;

        emit CreateNewOffer(address(0), min_price, min_deposit);
        vm.prank(makeAddr("emitTest"));
        factory.create_offer(12, min_price, min_deposit);
        address newOffer = factory.get_offersIdAddr(12);
        assertEq(factory.get_offersIdAddr(12), newOffer);
    }

    function testGet_idStructOffer() public {
        address offerr = factory.get_idStructOffer(15).offer;
        assertEq(factory.get_idStructOffer(15).offer, offerr);
        assertEq(factory.get_idStructOffer(15).min_price, 100);
        assertEq(factory.get_idStructOffer(15).min_deposit, 1000);
    }

    function testGet_offersId() public {
        uint[] memory id = factory.get_offersId();

        assertEq(factory.get_offersId(), id);
    }

    function testReceive() public {
        address myAddr = makeAddr("owner");
        deal(myAddr, 100 ether);
        vm.prank(myAddr);
        //console.log(myAddr.balance);
        payable(factory).transfer(100000);
        //console.log(address(factory).balance);
        assertEq(address(factory).balance, 100000);
        //console.log(factory.ownerFactory());
    }

    function testWithdrawComision() public {
        address myAddr = makeAddr("owner");
        deal(myAddr, 100 ether);
        vm.startPrank(myAddr);
        payable(factory).transfer(100000);
        vm.stopPrank();

        // address _ownerFactory = factory.ownerFactory();
        // uint _balancee = _ownerFactory.balance;
        uint _balance_contract = address(factory).balance;
        // console.log(address(this));

        address comissionOwner = makeAddr("ownerComsa");
        assertEq(comissionOwner.balance, 0);
        factory.withdrawComission(comissionOwner, _balance_contract);
        assertEq(comissionOwner.balance, _balance_contract);
    }

    function testWithdrawComisionNotAnOwnerFactory() public {
        vm.expectRevert(
            bytes("The function can only be called by the factory creator.")
        );
        vm.prank(makeAddr("pipi"));
        factory.withdrawComission(makeAddr("o"), 100);
    }

    function testWithdrawComisionLowComsa() public {
        vm.expectRevert(bytes("Failed!"));

        factory.withdrawComission(makeAddr("o"), 1000000);
    }
}
