#[abi]
trait IETHContract {
    #[external]
    fn transfer(recipient: starknet::ContractAddress, amount: u256);
    #[external]
    fn transferFrom(
        sender: starknet::ContractAddress, recipient: starknet::ContractAddress, amount: u256
    );
}

#[contract]
mod Wallet {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::get_contract_address;
    use super::IETHContractDispatcherTrait;
    use super::IETHContractDispatcher;


    struct Storage {
        wallets: LegacyMap::<ContractAddress, u256>
    }

    #[event]
    fn Deposit(user_adress: ContractAddress, amount: u256) {}

    #[event]
    fn Withdraw(user_adress: ContractAddress, amount: u256) {}

    #[view]
    fn contract_address() -> ContractAddress {
        let this_contract = get_contract_address();
        this_contract
    }

    #[view]
    fn get_balance(user_address: ContractAddress) -> u256 {
        wallets::read(user_address)
    }

    #[external]
    fn deposit(eth_contract_address: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        let caller_balance = get_balance(caller);
        let caller_new_balance = caller_balance + amount;
        IETHContractDispatcher {
            contract_address: eth_contract_address
        }.transferFrom(caller, contract_address(), amount);
        Deposit(caller, amount);
        wallets::write(caller, caller_new_balance);
    }

    #[external]
    fn withdraw(eth_contract_address: ContractAddress, amount: u256) {
        let caller = get_caller_address();
        let caller_balance = get_balance(caller);
        assert(caller_balance >= amount, 'Not enought funds');
        let caller_new_balance = caller_balance - amount;
        wallets::write(caller, caller_new_balance);
        IETHContractDispatcher { contract_address: eth_contract_address }.transfer(caller, amount);
        Withdraw(caller, amount);
    }
}
