## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N]' && read ans && [ $${ans:-N} = y ]

## test: run unit tests with forge
.PHONY: test
test:
	@echo 'Running tests...'
	forge test

## localnode: start a local node with anvil
.PHONY: localnode
localnode:
	@echo 'Starting local node...'
	anvil

## deploy/local k=$1: deploy contract to local node ($ make deploy/local k=<private_key>)
.PHONY: deploy/local
deploy/local: confirm
	@echo 'Deploying contract to local node...'
	forge script script/CryptoSoldiers.s.sol --rpc-url http://localhost:8545 --private-key $1 --broadcast -vvvv

## deploy/testnet: deploy contract to Ethereum testnet
.PHONY: deploy/testnet
deploy/testnet: confirm
	@echo 'Deploying contract to testnet... TODO: use cast wallet instead of --private-key'

## deploy/mainnet: deploy contract to Ethereum mainnet
.PHONY: deploy/mainnet
deploy/testnet: confirm
	@echo 'Deploying contract to mainnet... TODO: use cast wallet instead of --private-key; validate that it has not been deployed already'