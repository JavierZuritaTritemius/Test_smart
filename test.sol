// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IDelayOracle {
    function isTrainDelayed(uint256 trainId) external view returns (bool);
}

contract SimplifiedTrainRefund is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IDelayOracle public oracle;

    mapping(address => uint256) public payments;

    constructor(address oracleAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        oracle = IDelayOracle(oracleAddress);
    }

    // Usuario compra un billete enviando ETH
    function buyTicket() external payable whenNotPaused {
        require(msg.value > 0, "Debe enviar ETH");
        payments[msg.sender] += msg.value;
    }

    // Usuario pide reembolso si el tren se retrasó
    function requestRefund(uint256 trainId) external nonReentrant whenNotPaused {
        require(payments[msg.sender] > 0, "No hay pago registrado");
        require(oracle.isTrainDelayed(trainId), "El tren no se ha retrasado");

        uint256 refundAmount = payments[msg.sender];
        payments[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Fallo al reembolsar");
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Fallback para recibir ETH
    receive() external payable {}
}
