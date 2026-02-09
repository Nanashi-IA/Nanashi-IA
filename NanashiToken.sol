// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NanashiToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Taxe fixe : 1% sur TOUTES les transactions (buy/sell/transfer)
    uint256 public constant FOUNDER_TAX = 100; // 100 basis points = 1%

    address public founderWallet; // Wallet du fondateur qui reçoit 1% de chaque tx

    event FounderTaxSent(address indexed from, address indexed to, uint256 amount);
    event FounderWalletUpdated(address indexed newWallet);

    constructor(address _founderWallet) ERC20("Nanashi Token", "$NANA") {
        require(_founderWallet != address(0), "Invalid founder wallet address");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        founderWallet = _founderWallet;

        // Mint initial : 1 milliard $NANA (ajustable)
        _mint(msg.sender, 1_000_000_000 * 10**decimals());
    }

    // Mint (seulement par MINTER_ROLE, pour rewards mining ou airdrops)
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Pause / Unpause (urgence, seulement owner)
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Mise à jour du wallet fondateur
    function updateFounderWallet(address newWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newWallet != address(0), "Invalid founder wallet");
        founderWallet = newWallet;
        emit FounderWalletUpdated(newWallet);
    }

    // Override _transfer : 1% sur TOUTES les transactions vers le founderWallet
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        uint256 taxAmount = (amount * FOUNDER_TAX) / 10000; // 1%

        if (taxAmount > 0 && founderWallet != address(0)) {
            super._transfer(from, founderWallet, taxAmount);
            emit FounderTaxSent(from, founderWallet, taxAmount);
        }

        super._transfer(from, to, amount - taxAmount);
    }

    // Renonce à tous les rôles (admin + minter) – fair launch, plus de contrôle centralisé
    function renounceAllRoles() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        renounceRole(MINTER_ROLE, msg.sender);
    }

    // Claim rewards (placeholder – à connecter à ton système mining)
    function claimRewards(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        // Logique future : mint reward ou transfert depuis reserve
        // Exemple : _mint(msg.sender, amount * 2); // double reward
    }
}
