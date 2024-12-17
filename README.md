# StackSafe Vault

A secure, decentralized time-locked wallet for STX assets with yield farming capabilities, multi-signature authorization, and emergency beneficiary access.

## Overview

StackSafe Vault is a smart contract designed to provide secure, long-term storage for STX assets while enabling yield generation through farming mechanisms. It incorporates multiple security features including time-locks, multi-signature requirements, and emergency access protocols.

### Key Features

- **Time-Locked Storage**: Lock assets for a specified period
- **Yield Farming**: Earn yields on locked assets
- **Multi-Signature Security**: Require multiple authorized signers for withdrawals
- **Emergency Access**: Beneficiary system for account recovery
- **Owner Controls**: Flexible management of contract parameters

## Technical Architecture

### Core Components

1. **Vault Management**
   - Time-lock mechanism
   - Balance tracking
   - Owner controls
   - Beneficiary system

2. **Yield Farming**
   - Position tracking
   - Yield calculation
   - Claim management
   - Rate adjustment

3. **Multi-Signature System**
   - Signer authorization
   - Signature tracking
   - Withdrawal rounds
   - Signature verification

### Security Features

- Input validation
- Principal verification
- Self-transfer prevention
- Balance checks
- Time-lock enforcement
- Multi-signature verification

## Installation

1. Clone the repository
2. Deploy using Clarinet
3. Initialize the contract with desired parameters

```bash
# Deploy using Clarinet
clarinet contract deploy

# Initialize contract
contract-call? .stacksafe-vault initialize-vault u52560 u3 none
```

## Usage Guide

### Contract Initialization

```clarity
;; Initialize vault with 1-year lock, 3 required signatures, no beneficiary
(contract-call? .stacksafe-vault initialize-vault u52560 u3 none)

;; Initialize with beneficiary
(contract-call? .stacksafe-vault initialize-vault u52560 u3 (some ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM))
```

### Managing Signers

```clarity
;; Add authorized signer
(contract-call? .stacksafe-vault add-signer ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Remove signer
(contract-call? .stacksafe-vault remove-signer ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Depositing Funds

```clarity
;; Deposit 1000 STX
(contract-call? .stacksafe-vault deposit-stx u1000)
```

### Yield Farming

```clarity
;; Start yield farming with 500 STX
(contract-call? .stacksafe-vault start-yield-farming u500)

;; Claim accrued yield
(contract-call? .stacksafe-vault claim-yield)

;; End farming position
(contract-call? .stacksafe-vault end-yield-farming)
```

### Withdrawals

```clarity
;; Start withdrawal round
(contract-call? .stacksafe-vault start-withdrawal)

;; Sign withdrawal (by authorized signers)
(contract-call? .stacksafe-vault sign-withdrawal)

;; Execute withdrawal
(contract-call? .stacksafe-vault withdraw u100)
```

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Already initialized |
| u102 | Not initialized |
| u103 | Lock active |
| u104 | Insufficient signatures |
| u105 | Invalid beneficiary |
| u106 | Lock expired |
| u112 | Yield farming active |
| u113 | No yield farming |
| u114 | Insufficient balance |
| u115 | Invalid principal |
| u116 | Self transfer |

## Contract Functions

### Read-Only Functions
- `get-lock-expiry`: Get lock expiration block height
- `get-vault-balance`: Get total vault balance
- `get-token-balance`: Get balance for specific token
- `get-withdrawal-id`: Get current withdrawal round ID
- `get-current-signature-count`: Get signatures for current round
- `is-authorized-signer`: Check if address is authorized signer
- `get-yield-farming-status`: Check if yield farming is active
- `get-total-yield-earned`: Get total yield earned
- `get-yield-position`: Get farming position details

### Public Functions
- `initialize-vault`: Set up vault parameters
- `add-signer`: Add authorized signer
- `remove-signer`: Remove authorized signer
- `deposit-stx`: Deposit STX tokens
- `start-yield-farming`: Begin yield farming
- `claim-yield`: Claim accrued yield
- `end-yield-farming`: End farming position
- `sign-withdrawal`: Sign withdrawal request
- `withdraw`: Execute withdrawal
- `update-beneficiary`: Update emergency beneficiary
- `transfer-ownership`: Transfer contract ownership
- `update-yield-rate`: Update yield rate

## Security Considerations

1. **Time-Lock Safety**
   - Minimum lock period enforcement
   - Block height validation
   - Emergency access delay

2. **Multi-Signature Security**
   - Signer validation
   - Signature threshold enforcement
   - Round-based signature tracking

3. **Yield Farming Safety**
   - Balance checks
   - Position tracking
   - Rate limits

## Development

### Prerequisites
- Clarity language understanding
- Clarinet installed
- STX testnet access

### Testing
Run the test suite using Clarinet:
```bash
clarinet test
```

### Deployment
1. Configure deployment settings
2. Deploy to testnet/mainnet
3. Initialize contract parameters

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Submit pull request

## License

MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Submit GitHub issue
2. Join community Discord
3. Check documentation

## Acknowledgments

Built with:
- Clarity Smart Contract Language
- Stacks Blockchain
- Clarinet Testing Framework