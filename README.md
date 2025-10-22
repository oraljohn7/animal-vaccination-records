# Animal Vaccination Records

A blockchain-based system for tracking animal vaccinations with health compliance verification and digital certificate issuance.

## Overview

The Animal Vaccination Records system provides veterinarians and pet owners with a secure, transparent, and immutable platform for tracking immunization history and health compliance requirements. This smart contract solution ensures that vaccination records are permanently stored, easily verifiable, and accessible to authorized parties.

## Real-Life Use Case

Veterinarians maintain pet vaccination records for travel and boarding requirements. This system provides digital verification and compliance tracking, making it easier for:

- **Pet owners** to access and share vaccination history
- **Veterinarians** to maintain accurate health records
- **Boarding facilities** to verify compliance requirements
- **Travel authorities** to confirm required immunizations

## Features

- **Vaccination Record Tracking**: Store comprehensive vaccination details including vaccine type, date, and administering veterinarian
- **Health Compliance Verification**: Automatically verify if animals meet health compliance requirements
- **Digital Certificate Issuance**: Generate verifiable digital certificates for vaccinations
- **Immutable Records**: Leverage blockchain technology to prevent tampering or alteration of vaccination history
- **Authorization Controls**: Ensure only authorized veterinarians can create or update records

## Smart Contract

### vaccination-tracker

The main smart contract that manages all vaccination-related operations:

- Record new vaccinations
- Retrieve vaccination history
- Verify compliance status
- Issue digital certificates
- Manage authorized veterinarians

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for deployment

### Installation

```bash
# Clone the repository
git clone https://github.com/oraljohn7/animal-vaccination-records.git

# Navigate to project directory
cd animal-vaccination-records

# Check contract syntax
clarinet check

# Run tests
npm test
```

### Development

```bash
# Create new contract
clarinet contract new <contract-name>

# Check all contracts
clarinet check

# Run Clarinet console
clarinet console
```

## Contract Functions

### Public Functions

- `record-vaccination`: Record a new vaccination for an animal
- `get-vaccination-record`: Retrieve vaccination details by record ID
- `verify-compliance`: Check if an animal meets compliance requirements
- `issue-certificate`: Generate a digital vaccination certificate
- `add-authorized-vet`: Add a veterinarian to the authorized list (admin only)

### Read-Only Functions

- `get-animal-history`: Retrieve complete vaccination history for an animal
- `check-certificate-validity`: Verify the authenticity of a digital certificate
- `get-compliance-status`: Check current compliance status

## Data Structures

- **Vaccination Record**: Animal ID, vaccine type, date, veterinarian, certificate ID
- **Compliance Requirements**: Required vaccines, validity periods, renewal dates
- **Digital Certificates**: Unique certificate ID, issuance date, expiration date

## Security Considerations

- Only authorized veterinarians can create vaccination records
- Contract deployer has admin privileges
- Vaccination records are immutable once created
- Certificate verification prevents fraud

## Testing

The project includes comprehensive tests for all contract functions:

```bash
npm test
```

## Deployment

### Testnet Deployment

```bash
# Deploy to testnet
clarinet deployments apply -p testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet
clarinet deployments apply -p mainnet
```

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass
2. Code follows Clarity best practices
3. Documentation is updated

## License

MIT License

## Support

For issues or questions, please open an issue on GitHub or contact the development team.

## Roadmap

- [ ] Multi-species support with specific vaccine requirements
- [ ] Integration with veterinary practice management systems
- [ ] Mobile app for pet owners
- [ ] International travel compliance checker
- [ ] Automated reminder system for vaccine renewals

---

**Built with Clarity on Stacks blockchain**
