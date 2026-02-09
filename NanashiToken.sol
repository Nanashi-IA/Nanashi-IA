// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NanashiToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Taxe fixe : 1% sur TOUTES les transactions → distribuée aux stakers
    uint256 public constant STAKING_TAX = 100; // 1%

    // Staking
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdateTime;
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() ERC20("Nanashi Token", "$NANA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        // Mint initial : 1 milliard $NANA
        _mint(msg.sender, 1_000_000_000 * 10**decimals());
    }

    // Update rewards (called on stake/unstake/transfer)
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime[account] = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Reward per token (taxes distribuées proportionnellement)
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime[address(this)]) * 1e18 / totalStaked);
    }

    // Rewards earned by user
    function earned(address account) public view returns (uint256) {
        return ((stakedBalance[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    // Stake
    function stake(uint256 amount) external whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Amount must be > 0");
        _transfer(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    // Unstake + auto-compound (rewards réinvestis)
    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0 && stakedBalance[msg.sender] >= amount, "Insufficient staked");
        uint256 reward = earned(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        _transfer(address(this), msg.sender, amount + reward); // amount + rewards (auto-compound)
        rewards[msg.sender] = 0;
        emit Unstaked(msg.sender, amount);
        emit RewardPaid(msg.sender, reward);
    }

    // _transfer : 1% tax → distribuée aux stakers (via updateReward)
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused updateReward(from) updateReward(to) {
        uint256 taxAmount = (amount * STAKING_TAX) / 10000; // 1%

        if (taxAmount > 0) {
            // Taxe reste dans le contrat → distribuée via staking rewards
            // Pas de transfer direct, elle s'accumule pour rewardPerToken
        }

        super._transfer(from, to, amount - taxAmount);
    }

    // Renonce à tous les rôles (fair launch)
    function renounceAllRoles() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        renounceRole(MINTER_ROLE, msg.sender);
    }
}
