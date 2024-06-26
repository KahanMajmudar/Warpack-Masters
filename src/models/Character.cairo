use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Character {
    #[key]
    player: ContractAddress,
    // must be less than 31 ASCII characters
    name: felt252,
    wmClass: WMClass,
    gold: usize,
    health: usize,
    wins: usize,
    loss: usize,
    dummied: bool,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum WMClass {
    Warrior,
    Warlock,
}

