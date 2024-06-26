#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use warpack_masters::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::backpack::{Backpack, backpack, Grid, GridTrait},
        models::Item::{Item, item, ItemsCounter}, models::CharacterItem::{Position},
        models::Character::{Character, character, WMClass},
    };

    use warpack_masters::systems::actions::actions::ITEMS_COUNTER_ID;


    #[test]
    #[available_gas(30000000)]
    fn test_spawn() {
        let caller = starknet::contract_address_const::<0x0>();

        let mut models = array![backpack::TEST_CLASS_HASH, character::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('Alice', WMClass::Warlock);

        let backpack = get!(world, caller, Backpack);

        assert(!backpack.grid.is_zero(), 'grid should not be 0');
    }

    #[test]
    #[should_panic]
    #[available_gas(30000000)]
    fn test_spawn_already_exists() {
        let mut models = array![backpack::TEST_CLASS_HASH, character::TEST_CLASS_HASH];

        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.spawn('Alice', WMClass::Warlock);

        actions_system.spawn('Bob', WMClass::Warrior);
    }
}
