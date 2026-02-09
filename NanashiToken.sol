// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NanashiToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Taxe fixe : 1% sur TOUTES les transactions → au founderWallet
    uint256 public constant FOUNDER_TAX = 100; // 1%

    address public founderWallet;

    // Anti-bot (ajustable si besoin)
    uint256 public maxTxAmount = totalSupply() * 1 / 100; // 1% supply max par tx
    uint256 public maxWalletAmount = totalSupply() * 2 / 100; // 2% supply max par wallet

    // Staking basique
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakedTime;
    uint256 public totalStaked;
    uint256 public rewardRate = 10; // 10% APY approximatif (ajustable)

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event FounderTaxSent(address indexed from, address indexed to, uint256 amount);
    event FounderWalletUpdated(address indexed newWallet);

    constructor(address _founderWallet) ERC20("Nanashi Token", "$NANA") {
        require(_founderWallet != address(0), "Invalid founder wallet");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        founderWallet = _founderWallet;

        _mint(msg.sender, 1_000_000_000 * 10**decimals());
    }

    // Mint (seulement par MINTER_ROLE)
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Pause / Unpause
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Update founder wallet
    function updateFounderWallet(address newWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newWallet != address(0), "Invalid founder wallet");
        founderWallet = newWallet;
        emit FounderWalletUpdated(newWallet);
    }

    // Override _transfer : taxe 1% + anti-bot
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        // Anti-bot checks (exempt owner + founder)
        if (from != owner() && to != owner() && from != founderWallet && to != founderWallet) {
            require(amount <= maxTxAmount, "Tx amount exceeds max");
            require(balanceOf(to) + amount <= maxWalletAmount, "Wallet exceeds max");
        }

        uint256 taxAmount = (amount * FOUNDER_TAX) / 10000; // 1%

        if (taxAmount > 0 && founderWallet != address(0)) {
            super._transfer(from, founderWallet, taxAmount);
            emit FounderTaxSent(from, founderWallet, taxAmount);
        }

        super._transfer(from, to, amount - taxAmount);
    }

    // Staking functions
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        stakedTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0 && stakedBalance[msg.sender] >= amount, "Insufficient staked");
        uint256 reward = calculateReward(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        _transfer(address(this), msg.sender, amount + reward);
        emit Unstaked(msg.sender, amount);
        emit RewardPaid(msg.sender, reward);
    }

    function calculateReward(address user) public view returns (uint256) {
        if (stakedBalance[user] == 0) return 0;
        uint256 timeStaked = block.timestamp - stakedTime[user];
        return (stakedBalance[user] * rewardRate * timeStaked) / (365 days * 100);
    }

    // Renonce à tous les rôles (fair launch)
    function renounceAllRoles() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        renounceRole(MINTER_ROLE, msg.sender);
    }

    // Claim rewards placeholder
    function claimRewards(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
    }
}
