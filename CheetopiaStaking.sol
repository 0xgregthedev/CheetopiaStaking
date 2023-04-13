//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";

//@GregTheDev
contract CheetopiaStaking is Ownable {
    error NotStaked();
    error TransferFailed();

    address private immutable _CHEETOPIA;
    mapping(address => mapping(uint256 => bool)) private _userStakingData;

    constructor(address CHEETOPIA_) payable {
        _CHEETOPIA = CHEETOPIA_;
    }

    function stake(uint256 tokenId) external {
        assembly {
            //Load free memory pointer
            let ptr := mload(0x40)
            //Get location of this address and token in _userStakingData
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            mstore(0x00, tokenId)

            //Update _userStakingData
            sstore(keccak256(0x0, 0x40), 0x1)

            //Transfer nft from caller to contract
            mstore(0x0, 0x23b872dd) //'transferFrom(address,address,uint256)' selector
            mstore(0x20, caller()) //'from'
            mstore(0x40, address()) //'to'
            mstore(0x60, tokenId) //'tokenId'

            //prettier-ignore
            //If transfer fails, revert TransferFailed()
            if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, 0x1C, 0x64, 0x0, 0x0)) {
                mstore(0x0, 0x90b8ec18) //'TransferFailed()' selector
                revert(0x1c, 0x04)
            }
            mstore(0x40, ptr) //Restore pointer
            mstore(0x60, 0x0) //Restore zero slot
        }
    }

    function stakeBatch(uint256[] calldata tokenIds) external {
        assembly {
            //Load free memory pointer
            let ptr := mload(0x40)
            //Cache _userStakingData location for this address.
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))

            mstore(ptr, 0x23b872dd) //"transferFrom(address,address,uint256)" selector
            mstore(add(ptr, 0x20), caller()) //'from'
            mstore(add(ptr, 0x40), address()) //'to'
            let selectorOffset := add(ptr, 0x1C)
            let idOffset := add(ptr, 0x60)
            let n := calldatasize()
            //prettier-ignore
            for {let i := tokenIds.offset} lt(i, n) {i := add(i, 0x20)} {
                let id := calldataload(i)
                //Update _userStakingData
                mstore(0x0, id)
                sstore(keccak256(0x0, 0x40), 0x1)

                //Transfer from caller to contract. If transfer fails revert.
                mstore(idOffset, id)
                //prettier-ignore
                if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, selectorOffset, 0x64, 0x0, 0x0)) {
                    mstore(0x0, 0x90b8ec18) //store TransferFailed()
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x40, ptr) //Restore pointer
        }
    }

    function unstake(uint256 tokenId) external {
        assembly {
            //Cache Free memory pointer
            let ptr := mload(0x40)
            //Cache _userStakingData location for this address.
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            mstore(0x0, tokenId)
            let location := keccak256(0x0, 0x40)

            //If not staked revert NotStaked()
            if iszero(sload(location)) {
                mstore(0x0, 0x039f2e18) //'NotStaked()' selector
                revert(0x1c, 0x04)
            }
            //Update _userStakingData mapping
            sstore(location, 0x0)

            mstore(0x0, 0x23b872dd) //'transferFrom(address,address,uint256)' selector
            mstore(0x20, address()) //'from'
            mstore(0x40, caller()) //'to'
            mstore(0x60, tokenId) //'tokenId'
            //prettier-ignore
            //If transfer fails, revert TransferFailed()
            if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, 0x1C, 0x64, 0x0, 0x0)) {
                mstore(0x0, 0x90b8ec18) //'TransferFailed()' selector
                revert(0x1c, 0x04)
            }
            mstore(0x40, ptr) //Restore pointer
            mstore(0x60, 0x0) //Restore zero space
        }
    }

    function unstakeBatch(uint256[] calldata tokenIds) external {
        assembly {
            //Cache slot in _userStakingData for this address
            mstore(0x0, caller())
            mstore(0x20, _userStakingData.slot)
            mstore(0x20, keccak256(0x0, 0x40))
            //Get free memory pointer
            let ptr := mload(0x40)
            mstore(ptr, 0x23b872dd) //"transferFrom(address,address,uint256)" selector
            mstore(add(ptr, 0x20), address()) //'from'
            mstore(add(ptr, 0x40), caller()) //'to'
            let selectorOffset := add(ptr, 0x1C)
            let idOffset := add(ptr, 0x60)
            let n := calldatasize()
            //prettier-ignore
            for {let i := tokenIds.offset} lt(i, n) {i := add(i, 0x20)} {
                let id := calldataload(i)
                //Store complete location of tokenId in userStakingData.
                mstore(0x0, id)
                let location := keccak256(0x0, 0x40)
                //If not staked revert.
                if iszero(sload(location)) {
                    mstore(0x0, 0x039f2e18) //store NotStaked() selector
                    revert(0x1c, 0x04)
                }
                //Update _userStakingData map
                sstore(location, 0x0)

                mstore(idOffset, id) //'tokenId'
                //prettier-ignore
                //If Transfer fails revert TransferFailed()
                if iszero(call(gas(), sload(_CHEETOPIA.slot), 0x0, selectorOffset, 0x64, 0x0, 0x0)) {
                    //prettier-ignore
                    mstore(0x0, 0x90b8ec18) //store TransferFailed() selector
                    revert(0x1c, 0x04)
                }
            }
            //Restore free memory pointer
            mstore(0x40, ptr)
        }
    }

    function setCHEETOPIA(address CHEETOPIA_) external onlyOwner {
        _CHEETOPIA = CHEETOPIA_;
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
