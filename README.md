# Crypto Will - Smart Contract Digital Inheritance System

A blockchain-based digital inheritance system that automatically transfers ownership of a Gnosis Safe wallet to designated heirs when the original owner becomes inactive for a specified period.

## Overview

This project implements a "dead man's switch" mechanism for cryptocurrency wallets using the Gnosis Safe multisig wallet system. The smart contract monitors the owner's activity through a "ping" mechanism and automatically transfers wallet ownership to a designated heir if the owner fails to check in for a predetermined time period.

### Key Features

- **Ping Mechanism**: Owner must periodically "ping" the contract to prove they are still active
- **Automatic Inheritance**: If ping threshold expires, designated heir can claim wallet ownership
- **Safe Integration**: Built as a module for Gnosis Safe wallets
- **Time-based Security**: Configurable inactivity period before inheritance activation
- **Single Heir Support**: Transfers complete wallet control to one designated beneficiary

## License

This project is licensed under LGPL-3.0.