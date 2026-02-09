// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NanashiToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ────────────────────────────────────────────────────────────────
    // CONFIGURATION GLOBALE
    // ────────────────────────────────────────────────────────────────

    // Taxe fixe : 1% sur TOUTES les transactions → redistribuée aux stakers
    uint256 public constant STAKING_TAX = 100; // 100 basis points = 1%

    // Anti-bot protection (activé par défaut au lancement)
    bool public antiBotEnabled = true;
    uint256 public maxTxAmount;      // 1% du supply max par transaction
    uint256 public maxWalletAmount;  // 2% du supply max par wallet

    address public founderWallet;    // Wallet initial du fondateur (avant renounce)

    // Staking
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;
    uint256 public lastRewardUpdate;

    // Blacklist
    mapping(address => bool) public blacklisted;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event FounderTaxSent(address indexed from, address indexed to, uint256 amount);
    event FounderWalletUpdated(address indexed newWallet);
    event AntiBotToggled(bool enabled);
    event Blacklisted(address indexed account, bool status);

    // ────────────────────────────────────────────────────────────────
    // CONSTRUCTOR
    // ────────────────────────────────────────────────────────────────

    constructor(address _founderWallet) ERC20("Nanashi Token", "$NANA") {
        require(_founderWallet != address(0), "Invalid founder wallet");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        founderWallet = _founderWallet;

        // Initial supply
        uint256 initialSupply = 1_000_000_000 * 10**decimals();
        _mint(msg.sender, initialSupply);

        // Anti-bot settings (1% et 2% du supply initial)
        maxTxAmount = initialSupply / 100;
        maxWalletAmount = initialSupply * 2 / 100;

        lastRewardUpdate = block.timestamp;
    }

    // ────────────────────────────────────────────────────────────────
    // MODIFIERS
    // ────────────────────────────────────────────────────────────────

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        if (account != address(0)) {
            rewards[account] += earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Address is blacklisted");
        _;
    }

    // ────────────────────────────────────────────────────────────────
    // ANTI-BOT FUNCTIONS
    // ────────────────────────────────────────────────────────────────

    function toggleAntiBot(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiBotEnabled = enabled;
        emit AntiBotToggled(enabled);
    }

    function blacklistAddress(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[account] = status;
        emit Blacklisted(account, status);
    }

    // ────────────────────────────────────────────────────────────────
    // STAKING & REWARDS (taxes redistribuées aux stakers)
    // ────────────────────────────────────────────────────────────────

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) return rewardPerTokenStored;

        uint256 timeSinceLastUpdate = block.timestamp - lastRewardUpdate;
        uint256 taxRewards = timeSinceLastUpdate * STAKING_TAX * 1e18 / (365 days * 100); // Approximation

        return rewardPerTokenStored + (taxRewards / totalStaked);
    }

    function earned(address account) public view returns (uint256) {
        return ((stakedBalance[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function stake(uint256 amount) external whenNotPaused updateReward(msg.sender) notBlacklisted(msg.sender) {
        require(amount > 0, "Amount must be > 0");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        lastRewardUpdate = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0 && stakedBalance[msg.sender] >= amount, "Insufficient staked");
        uint256 reward = earned(msg.sender);

        // Auto-compound : rewards réinvestis dans le stake
        uint256 totalToReceive = amount + reward;
        stakedBalance[msg.sender] -= amount;
        rewards[msg.sender] = 0;
        totalStaked -= amount;
        lastRewardUpdate = block.timestamp;

        _transfer(address(this), msg.sender, totalToReceive);
        emit Unstaked(msg.sender, amount);
        emit RewardPaid(msg.sender, reward);
    }

    // ────────────────────────────────────────────────────────────────
    // TRANSFERT AVEC TAXE REDISTRIBUÉE AUX STAKERS
    // ────────────────────────────────────────────────────────────────

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused updateReward(from) updateReward(to) notBlacklisted(from) notBlacklisted(to) {
        // Anti-bot checks (exempt owner, founder, contract)
        if (antiBotEnabled && from != owner() && to != owner() && from != founderWallet && to != founderWallet && from != address(this) && to != address(this)) {
            require(amount <= maxTxAmount, "Tx amount exceeds max");
            require(balanceOf(to) + amount <= maxWalletAmount, "Wallet exceeds max");
        }

        uint256 taxAmount = (amount * STAKING_TAX) / 10000; // 1%

        if (taxAmount > 0) {
            // Taxe reste dans le contrat → distribuée via staking rewards
            super._transfer(from, address(this), taxAmount);
        }

        super._transfer(from, to, amount - taxAmount);
    }

    // ────────────────────────────────────────────────────────────────
    // AUTRES FONCTIONS
    // ────────────────────────────────────────────────────────────────

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function renounceAllRoles() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        renounceRole(MINTER_ROLE, msg.sender);
    }

    function claimRewards(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
    }
}
