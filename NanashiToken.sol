// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NanashiToken is ERC20, ERC20Burnable, Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant STAKING_TAX = 100; // 1% (100 basis points)

    // Anti-bot (activé au lancement, désactivable définitivement)
    bool public antiBotEnabled = true;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    // Staking & Rewards (basés sur taxes réelles collectées)
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;

    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;
    uint256 public totalTaxesCollected; // Tracker des taxes réelles

    // Blacklist
    mapping(address => bool) public blacklisted;

    // Timelock renounce (30 jours)
    uint256 public constant RENOUNCE_TIMELOCK = 30 days;
    uint256 public renounceTimestamp;
    bool public rolesRenounced = false;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event AntiBotToggled(bool enabled);
    event Blacklisted(address indexed account, bool status);
    event RolesRenounced(address indexed admin);

    constructor() ERC20("Nanashi Token", "$NANA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        uint256 initialSupply = 1_000_000_000 * 10**decimals();
        _mint(msg.sender, initialSupply); // Vers multisig recommandé

        maxTxAmount = initialSupply / 100;     // 1%
        maxWalletAmount = initialSupply * 2 / 100; // 2%

        renounceTimestamp = block.timestamp + RENOUNCE_TIMELOCK;
    }

    modifier updateReward(address account) {
        _distributeTaxesAsRewards();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Blacklisted");
        _;
    }

    function _distributeTaxesAsRewards() internal {
        if (totalTaxesCollected > 0 && totalStaked > 0) {
            rewardPerTokenStored += (totalTaxesCollected * 1e18) / totalStaked;
            totalTaxesCollected = 0;
        }
    }

    function earned(address account) public view returns (uint256) {
        return ((stakedBalance[account] * (rewardPerTokenStored - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function stake(uint256 amount) external whenNotPaused updateReward(msg.sender) notBlacklisted(msg.sender) nonReentrant {
        require(amount > 0, "Amount > 0");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external updateReward(msg.sender) nonReentrant {
        require(amount > 0 && stakedBalance[msg.sender] >= amount, "Insufficient staked");
        uint256 reward = rewards[msg.sender];
        uint256 totalToReceive = amount + reward;

        stakedBalance[msg.sender] -= amount;
        rewards[msg.sender] = 0;
        totalStaked -= amount;

        _transfer(address(this), msg.sender, totalToReceive);
        emit Unstaked(msg.sender, amount);
        emit RewardPaid(msg.sender, reward);
    }

    function claimRewards() external updateReward(msg.sender) nonReentrant {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        rewards[msg.sender] = 0;
        _transfer(address(this), msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused notBlacklisted(from) notBlacklisted(to) updateReward(from) updateReward(to) {
        if (antiBotEnabled && from != owner() && to != owner() && from != address(this) && to != address(this)) {
            require(amount <= maxTxAmount, "Tx limit");
            require(balanceOf(to) + amount <= maxWalletAmount, "Wallet limit");
        }

        uint256 taxAmount = 0;
        if (from != address(this) && to != address(this)) {
            taxAmount = (amount * STAKING_TAX) / 10000;
            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
                totalTaxesCollected += taxAmount;
            }
        }

        super._transfer(from, to, amount - taxAmount);
    }

    // Admin functions
    function toggleAntiBot(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        antiBotEnabled = enabled;
        emit AntiBotToggled(enabled);
    }

    function blacklistAddress(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[account] = status;
        emit Blacklisted(account, status);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function renounceAllRolesAndPrivileges() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp >= renounceTimestamp, "Timelock not expired");
        require(!rolesRenounced, "Already renounced");
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(PAUSER_ROLE, msg.sender);
        antiBotEnabled = false;
        rolesRenounced = true;
        emit RolesRenounced(msg.sender);
    }
}
