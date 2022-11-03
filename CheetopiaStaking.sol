//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";



//@GregTheDev
contract CheetopiaStaking is Ownable {
    error NotStaked();
    error TransferFailed();
    
    address private _CHEETOPIA;
    mapping(address => mapping(uint256 => bool)) private _userStakingData;

    constructor(address CHEETOPIA) payable {
        _CHEETOPIA = CHEETOPIA;
    }

    function stake(uint256 tokenId) external {
        //Update _userStakingData mapping
        assembly {
            //Hash location for this address and token
            //in the _userStakingData mapping.
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            mstore(0x00, tokenId)
            //Update _userStakingData
            sstore(keccak256(0x0, 0x40), 0x1)

            //Get Free memory pointer
            let ptr := mload(0x40)
            //transfer nft from caller to contract
            mstore(ptr, 0x23b872dd)// mstore "transferFrom(address,address,uint256)" selector
            mstore(add(ptr, 0x20), caller())//Store 'From'
            mstore(add(ptr, 0x40), address())//Store 'To'
            mstore(add(ptr, 0x60), tokenId)//Store TokenId
            mstore(0x40, add(ptr, 0x80)) //Restore pointer
            //If transfer fails, revert TransferFailed()
            if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, add(ptr, 0x1C), mload(0x40), returndatasize(), returndatasize())) { //prettier-ignore
                mstore(0x0, 0x90b8ec18)//store TransferFailed() selector
                revert(0x1c, 0x04)
            }
        }
    }

    function stakeBatch(uint256[] calldata tokenIds) external {
        assembly {
            //Hash _userStaking data location
            //for this address and mstore.
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))

            //Get Free memory pointer
            let ptr := mload(0x40)

            //"transferFrom(address,address,uint256)" selector
            mstore(ptr, 0x23b872dd)
           
            mstore(add(ptr, 0x20), caller())//'from'
            mstore(add(ptr, 0x40), address())//'to'
            let idOffset := add(ptr, 0x60)
            let selectorOffset := add(ptr, 0x1C)
            let calldataOffset := add(ptr, 0x80)
            let n := calldatasize()
            for { let i := tokenIds.offset } lt(i, n) { i := add(i, 0x20) } {//prettier-ignore
                let id := calldataload(i)
                mstore(0x0, id)
                //Update _userStakingData map
                sstore(keccak256(0x0, 0x40), 0x1)

                mstore(idOffset, id)
                //Transfer nft from caller to contract.
                //If transfer fails, revert TransferFailed()
                if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, selectorOffset, calldataOffset, returndatasize(), returndatasize())) { //prettier-ignore
                    mstore(0x0, 0x90b8ec18)//store TransferFailed() selector
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x40, add(ptr, 0x80)) //Restore pointer
        }
    }

    function unstake(uint256 tokenId) external {
        assembly {
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            mstore(0x0, tokenId)
            let location := keccak256(0x0, 0x40)
            //If not staked revert NotStaked()
            if iszero(sload(location)) {
                mstore(0x0, 0x039f2e18)
                revert(0x1c, 0x04)
            }
            //Update _userStakingData mapping
            sstore(location, 0x0)
            //transfer nft from address(this) to msg.sender
            //Cache Free memory pointer
            let ptr := mload(0x40)
            //transfer nft from  contract to caller
            mstore(ptr, 0x23b872dd)//"transferFrom(address,address,uint256)" selector
            mstore(add(ptr, 0x20), address())//'from'
            mstore(add(ptr, 0x40), caller())//'to'
            mstore(add(ptr, 0x60), tokenId)//'tokenId'
            mstore(0x40, add(ptr, 0x80)) //Restore pointer
            //If transfer fails, revert TransferFailed()
            if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, add(ptr, 0x1C), mload(0x40), returndatasize(), returndatasize())) { //prettier-ignore
                mstore(0x0, 0x90b8ec18)//store TransferFailed() selector
                revert(0x1c, 0x04)
            }
        }
    }

    function unstakeBatch(uint256[] calldata tokenIds) external {
        assembly {
            //Hash _userStaking data location
            //for this address and mstore.
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            //Get free memory pointer
            let ptr := mload(0x40)
            //"transferFrom(address,address,uint256)" selector
            mstore(ptr, 0x23b872dd)
            mstore(add(ptr, 0x20), address())//'from'
            mstore(add(ptr, 0x40), caller())//'to'
            let idOffset := add(ptr, 0x60)
            let selectorOffset := add(ptr, 0x1C)
            let calldataOffset := add(ptr, 0x80)
            let n := calldatasize()
            for { let i := tokenIds.offset} lt(i, n) { i := add(i, 0x20) } { //prettier-ignore
                let id := calldataload(i)
                mstore(0x0, id)
                //Cache complete location of tokenId in userStaking data.
                let location := keccak256(0x0, 0x40)
                //If not staked revert NotStaked()
                if iszero(sload(location)) {
                    mstore(0x0, 0x039f2e18)
                    revert(0x1c, 0x04)
                }
                //Update _userStakingData map
                sstore(location, 0x0)
                //transfer nft from contract to caller
                mstore(idOffset, id)//'tokenId'
                //If Transfer fails, revert TransferFailed()
                if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, selectorOffset, calldataOffset, returndatasize(), returndatasize())) { //prettier-ignore
                    mstore(0x0, 0x90b8ec18)//store TransferFailed() selector
                    revert(0x1c, 0x04)
                }
            }
            //Restore free memory pointer
            mstore(0x40, add(ptr, 0x80))
        }
    }
   
    function setCHEETOPIA(address CHEETOPIA) external onlyOwner {
        _CHEETOPIA = CHEETOPIA;
    }

    function CHEETOPIA() external view returns (address) {
        return _CHEETOPIA;
    }

    function userStakingData(address staker, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _userStakingData[staker][tokenId];
    }
}
