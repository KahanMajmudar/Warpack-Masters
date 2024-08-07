use warpack_masters::models::Character::WMClass;

use starknet::ContractAddress;

#[dojo::interface]
trait IActions {
    fn spawn(name: felt252, wmClass: WMClass);
    fn place_item(storage_item_id: u32, x: usize, y: usize, rotation: usize);
    fn undo_place_item(inventory_item_id: u32);
    fn add_item(
        id: u32,
        name: felt252,
        itemType: u8,
        width: usize,
        height: usize,
        price: usize,
        damage: usize,
        cleansePoison: usize,
        chance: usize,
        cooldown: u8,
        rarity: u8,
        armor: u32,
        armorActivation: u8,
        regen: u32,
        regenActivation: u8,
        reflect: u32,
        reflectActivation: u8,
        poison: u32,
        poisonActivation: u8,
        empower: u32,
        empowerActivation: u8,
    );
    fn edit_item(item_id: u32, item_key: felt252, item_value: felt252);
    fn buy_item(item_id: u32);
    fn sell_item(storage_item_id: u32);
    fn is_world_owner(player: ContractAddress) -> bool;
    fn is_item_owned(player: ContractAddress, id: usize) -> bool;
    fn reroll_shop();
    fn fight();
    fn create_dummy();
    fn rebirth(name: felt252, wmClass: WMClass);
    fn prefine_dummy(level: usize);
}

// TODO: rename the count filed in counter model
// TODO: consider restruct inventory items in case too much items owned by player increasing the loop time

#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use warpack_masters::models::{backpack::{BackpackGrids}};
    use warpack_masters::models::{
        CharacterItem::{
            Position, CharacterItemsStorageCounter, CharacterItemStorage, CharacterItemInventory,
            CharacterItemsInventoryCounter
        },
        Item::{Item, ItemsCounter}
    };
    use warpack_masters::models::Character::{Character, WMClass, NameRecord};
    use warpack_masters::models::Shop::Shop;
    use warpack_masters::utils::random::{pseudo_seed, random};
    use warpack_masters::models::DummyCharacter::{DummyCharacter, DummyCharacterCounter};
    use warpack_masters::models::DummyCharacterItem::{
        DummyCharacterItem, DummyCharacterItemsCounter
    };
    use warpack_masters::models::BattleLog::{BattleLog, BattleLogCounter};
    use warpack_masters::items::{Backpack1, Backpack2};
    use warpack_masters::prdefined_dummies::{PredefinedItem, Dummy0, Dummy1};


    // #[event]
    // #[derive(Drop, starknet::Event)]
    // enum Event {
    //     BattleLogDetail: BattleLogDetail,
    // }

    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    struct BattleLogDetail {
        #[key]
        player: ContractAddress,
        #[key]
        battleLogId: usize,
        #[key]
        id: usize,
        whoTriggered: felt252,
        whichItem: usize,
        damageCaused: usize,
        isDodged: bool,
        cleansePoison: usize,
        buffType: felt252,
        regenHP: usize,
        player_remaining_health: usize,
        dummy_remaining_health: usize,
        player_armor_stacks: usize,
        player_regen_stacks: usize,
        player_reflect_stacks: usize,
        player_empower_stacks: usize,
        player_poison_stacks: usize,
        dummy_armor_stacks: usize,
        dummy_regen_stacks: usize,
        dummy_reflect_stacks: usize,
        dummy_empower_stacks: usize,
        dummy_poison_stacks: usize,
    }

    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    struct BuyItem {
        #[key]
        player: ContractAddress,
        itemId: usize,
        cost: usize,
        itemRarity: u8,
        birthCount: u32,
    }

    #[derive(Model, Copy, Drop, Serde)]
    #[dojo::event]
    struct SellItem {
        #[key]
        player: ContractAddress,
        itemId: usize,
        price: usize,
        itemRarity: u8,
        birthCount: u32,
    }

    const GRID_X: usize = 9;
    const GRID_Y: usize = 7;
    const INIT_GOLD: usize = 8;
    const INIT_HEALTH: usize = 25;

    const ITEMS_COUNTER_ID: felt252 = 'ITEMS_COUNTER_ID';

    const STORAGE_FLAG: usize = 999;

    const EFFECT_ARMOR: felt252 = 'armor';
    const EFFECT_REGEN: felt252 = 'regen';
    const EFFECT_REFLECT: felt252 = 'reflect';
    const EFFECT_EMPOWER: felt252 = 'empower';
    const EFFECT_POISON: felt252 = 'poison';
    const EFFECT_CLEANSE_POISON: felt252 = 'cleanse_poison';

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn spawn(world: IWorldDispatcher, name: felt252, wmClass: WMClass) {
            let player = get_caller_address();

            assert(name != '', 'name cannot be empty');

            let nameRecord = get!(world, name, NameRecord);
            assert(
                nameRecord.player == starknet::contract_address_const::<0>()
                    || nameRecord.player == player,
                'name already exists'
            );

            let player_exists = get!(world, player, (Character));
            assert(player_exists.name == '', 'player already exists');

            // Default the player has 2 Backpacks
            // Must add two backpack items when setup the game
            let item = get!(world, Backpack1::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');
            let item = get!(world, Backpack2::id, (Item));
            assert(item.itemType == 4, 'Invalid item type');

            set!(
                world,
                (
                    CharacterItemStorage { player, id: 1, itemId: Backpack1::id },
                    CharacterItemStorage { player, id: 2, itemId: Backpack2::id },
                    CharacterItemsStorageCounter { player, count: 2 },
                )
            );

            self.place_item(1, 4, 2, 0);
            self.place_item(2, 2, 2, 0);

            // keep the previous rating, totalWins and totalLoss during rebirth
            let prev_rating = player_exists.rating;
            let prev_total_wins = player_exists.totalWins;
            let prev_total_loss = player_exists.totalLoss;
            let prev_birth_count = player_exists.birthCount;
            let updatedAt = get_block_timestamp();

            // add one gold for reroll shop
            set!(
                world,
                (
                    Character {
                        player,
                        name,
                        wmClass,
                        gold: INIT_GOLD + 1,
                        health: INIT_HEALTH,
                        wins: 0,
                        loss: 0,
                        dummied: false,
                        rating: prev_rating,
                        totalWins: prev_total_wins,
                        totalLoss: prev_total_loss,
                        winStreak: 0,
                        birthCount: prev_birth_count + 1,
                        updatedAt,
                    },
                    NameRecord { name, player }
                )
            );
        }

        fn add_item(
            world: IWorldDispatcher,
            id: u32,
            name: felt252,
            itemType: u8,
            width: usize,
            height: usize,
            price: usize,
            damage: usize,
            cleansePoison: usize,
            chance: usize,
            cooldown: u8,
            rarity: u8,
            armor: u32,
            armorActivation: u8,
            regen: u32,
            regenActivation: u8,
            reflect: u32,
            reflectActivation: u8,
            poison: u32,
            poisonActivation: u8,
            empower: u32,
            empowerActivation: u8,
        ) {
            let player = get_caller_address();

            assert(self.is_world_owner(player), 'player not world owner');

            assert(width > 0 && width <= GRID_X, 'width not in range');
            assert(height > 0 && height <= GRID_Y, 'height not in range');

            assert(price > 0, 'price must be greater than 0');

            assert(
                rarity == 1 || rarity == 2 || rarity == 3 || (rarity == 0 && itemType == 4),
                'rarity not valid'
            );

            let counter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            if id > counter.count {
                set!(world, ItemsCounter { id: ITEMS_COUNTER_ID, count: id });
            }

            let item = Item {
                id,
                name,
                itemType,
                width,
                height,
                price,
                damage,
                cleansePoison,
                chance,
                cooldown,
                rarity,
                armor,
                armorActivation,
                regen,
                regenActivation,
                reflect,
                reflectActivation,
                poison,
                poisonActivation,
                empower,
                empowerActivation,
            };

            set!(world, (item));
        }

        fn edit_item(
            world: IWorldDispatcher, item_id: u32, item_key: felt252, item_value: felt252
        ) {
            let player = get_caller_address();

            assert(self.is_world_owner(player), 'player not world owner');

            let mut item_data = get!(world, item_id, (Item));

            match item_key {
                // name
                0 => {
                    item_data.name = item_value;
                    set!(world, (item_data,));
                },
                // itemType
                1 => {
                    let new_itemType: u8 = item_value.try_into().unwrap();

                    item_data.itemType = new_itemType;
                    set!(world, (item_data,));
                },
                // width
                2 => {
                    let new_width: usize = item_value.try_into().unwrap();
                    assert(new_width > 0 && new_width <= GRID_X, 'new_width not in range');

                    item_data.width = new_width;
                    set!(world, (item_data,));
                },
                // height
                3 => {
                    let new_height: usize = item_value.try_into().unwrap();
                    assert(new_height > 0 && new_height <= GRID_Y, 'new_height not in range');

                    item_data.height = new_height;
                    set!(world, (item_data,));
                },
                // price
                4 => {
                    let new_price: usize = item_value.try_into().unwrap();
                    assert(new_price > 0, 'new_price must be > 0');

                    item_data.price = new_price;
                    set!(world, (item_data,));
                },
                // damage
                5 => {
                    let new_damage: usize = item_value.try_into().unwrap();

                    item_data.damage = new_damage;
                    set!(world, (item_data,));
                },
                // cleansePoison
                6 => {
                    let new_cleansePoison: usize = item_value.try_into().unwrap();

                    item_data.cleansePoison = new_cleansePoison;
                    set!(world, (item_data,));
                },
                // chance
                7 => {
                    let new_chance: usize = item_value.try_into().unwrap();

                    item_data.chance = new_chance;
                    set!(world, (item_data,));
                },
                // cooldown
                8 => {
                    let new_cooldown: u8 = item_value.try_into().unwrap();

                    item_data.cooldown = new_cooldown;
                    set!(world, (item_data,));
                },
                // rarity
                9 => {
                    let new_rarity: u8 = item_value.try_into().unwrap();
                    assert(
                        new_rarity == 1 || new_rarity == 2 || new_rarity == 3,
                        'new_rarity not valid'
                    );

                    item_data.rarity = new_rarity;
                    set!(world, (item_data,));
                },
                // armor
                10 => {
                    let new_armor: usize = item_value.try_into().unwrap();

                    item_data.armor = new_armor;
                    set!(world, (item_data,));
                },
                // armorActivation
                11 => {
                    let new_armorActivation: u8 = item_value.try_into().unwrap();

                    item_data.armorActivation = new_armorActivation;
                    set!(world, (item_data,));
                },
                // regen
                12 => {
                    let new_regen: usize = item_value.try_into().unwrap();

                    item_data.regen = new_regen;
                    set!(world, (item_data,));
                },
                // regenActivation
                13 => {
                    let new_regenActivation: u8 = item_value.try_into().unwrap();

                    item_data.regenActivation = new_regenActivation;
                    set!(world, (item_data,));
                },
                // reflect
                14 => {
                    let new_reflect: usize = item_value.try_into().unwrap();

                    item_data.reflect = new_reflect;
                    set!(world, (item_data,));
                },
                // reflectActivation
                15 => {
                    let new_reflectActivation: u8 = item_value.try_into().unwrap();

                    item_data.reflectActivation = new_reflectActivation;
                    set!(world, (item_data,));
                },
                // poison
                16 => {
                    let new_poison: usize = item_value.try_into().unwrap();

                    item_data.poison = new_poison;
                    set!(world, (item_data,));
                },
                // poisonActivation
                17 => {
                    let new_poisonActivation: u8 = item_value.try_into().unwrap();

                    item_data.poisonActivation = new_poisonActivation;
                    set!(world, (item_data,));
                },
                // empower
                18 => {
                    let new_empower: usize = item_value.try_into().unwrap();

                    item_data.empower = new_empower;
                    set!(world, (item_data,));
                },
                // empowerActivation
                19 => {
                    let new_empowerActivation: u8 = item_value.try_into().unwrap();

                    item_data.empowerActivation = new_empowerActivation;
                    set!(world, (item_data,));
                },
                _ => { panic!("Invalid item_key: {}", item_key); }
            }
        }


        fn place_item(
            world: IWorldDispatcher, storage_item_id: u32, x: usize, y: usize, rotation: usize
        ) {
            let player = get_caller_address();

            assert(x < GRID_X, 'x out of range');
            assert(y < GRID_Y, 'y out of range');
            assert(
                rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270,
                'invalid rotation'
            );

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));

            assert(storageItem.itemId != 0, 'item not owned');

            let itemId = storageItem.itemId;
            let item = get!(world, itemId, (Item));

            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));

            // if the item is 1x1, occupy the empty grid
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.enabled, 'Already enabled');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                } else {
                    assert(playerBackpackGrids.enabled, 'Grid not enabled');
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: true
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                assert(xMax < GRID_X, 'item out of bound for x');
                assert(yMax < GRID_Y, 'item out of bound for y');

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.enabled, 'Already enabled');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        } else {
                            assert(playerBackpackGrids.enabled, 'Grid not enabled');
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: true
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut inventoryCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));
                if inventoryItem.itemId == 0 {
                    inventoryItem.itemId = itemId;
                    inventoryItem.position = Position { x, y };
                    inventoryItem.rotation = rotation;
                    isUpdated = true;
                    set!(world, (inventoryItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                inventoryCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemInventory {
                            player,
                            id: inventoryCounter.count,
                            itemId: itemId,
                            position: Position { x, y },
                            rotation,
                        },
                        CharacterItemsInventoryCounter { player, count: inventoryCounter.count },
                    )
                );
            }

            storageItem.itemId = 0;
            set!(world, (storageItem));
        }

        fn undo_place_item(world: IWorldDispatcher, inventory_item_id: u32) {
            let player = get_caller_address();

            let mut inventoryItem = get!(
                world, (player, inventory_item_id), (CharacterItemInventory)
            );
            let itemId = inventoryItem.itemId;
            assert(itemId != 0, 'invalid inventory item id');
            let item = get!(world, itemId, (Item));

            let x = inventoryItem.position.x;
            let y = inventoryItem.position.y;
            let rotation = inventoryItem.rotation;
            let itemHeight = item.height;
            let itemWidth = item.width;

            let playerBackpackGrids = get!(world, (player, x, y), (BackpackGrids));
            if itemHeight == 1 && itemWidth == 1 {
                if item.itemType == 4 {
                    assert(!playerBackpackGrids.occupied, 'Already occupied');
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: false, occupied: false
                        })
                    );
                } else {
                    set!(
                        world,
                        (BackpackGrids {
                            player: player, x: x, y: y, enabled: true, occupied: false
                        })
                    );
                }
            } else {
                let mut xMax = 0;
                let mut yMax = 0;

                // only check grids which are above the starting (x,y)
                if rotation == 0 || rotation == 180 {
                    xMax = x + itemWidth - 1;
                    yMax = y + itemHeight - 1;
                }

                // only check grids which are to the right of the starting (x,y)
                if rotation == 90 || rotation == 270 {
                    //item_h becomes item_w and vice versa
                    xMax = x + itemHeight - 1;
                    yMax = y + itemWidth - 1;
                }

                let mut i = x;
                let mut j = y;
                loop {
                    if i > xMax {
                        break;
                    }
                    loop {
                        if j > yMax {
                            break;
                        }

                        let playerBackpackGrids = get!(world, (player, i, j), (BackpackGrids));
                        if item.itemType == 4 {
                            assert(!playerBackpackGrids.occupied, 'Already occupied');
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: false, occupied: false
                                })
                            );
                        } else {
                            set!(
                                world,
                                (BackpackGrids {
                                    player: player, x: i, y: j, enabled: true, occupied: false
                                })
                            );
                        }

                        j += 1;
                    };
                    j = y;
                    i += 1;
                }
            }

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = itemId;
                    isUpdated = true;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemStorage { player, id: storageCounter.count, itemId: itemId, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            inventoryItem.itemId = 0;
            inventoryItem.position.x = 0;
            inventoryItem.position.y = 0;
            inventoryItem.rotation = 0;
            set!(world, (inventoryItem));
        }

        fn buy_item(world: IWorldDispatcher, item_id: u32) {
            let player = get_caller_address();

            assert(item_id != 0, 'invalid item_id');

            let mut shop_data = get!(world, player, (Shop));
            assert(
                shop_data.item1 == item_id
                    || shop_data.item2 == item_id
                    || shop_data.item3 == item_id
                    || shop_data.item4 == item_id,
                'item not on sale'
            );

            let item = get!(world, item_id, (Item));
            let mut player_char = get!(world, player, (Character));

            assert(player_char.gold >= item.price, 'Not enough gold');
            player_char.gold -= item.price;

            //delete respective item bought from the shop
            if (shop_data.item1 == item_id) {
                shop_data.item1 = 0
            } else if (shop_data.item2 == item_id) {
                shop_data.item2 = 0
            } else if (shop_data.item3 == item_id) {
                shop_data.item3 = 0
            } else if (shop_data.item4 == item_id) {
                shop_data.item4 = 0
            }

            let mut storageCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageCounter.count;
            let mut isUpdated = false;
            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));
                if storageItem.itemId == 0 {
                    storageItem.itemId = item_id;
                    isUpdated = true;
                    set!(world, (storageItem));
                    break;
                }

                count -= 1;
            };

            if isUpdated == false {
                storageCounter.count += 1;
                set!(
                    world,
                    (
                        CharacterItemStorage { player, id: storageCounter.count, itemId: item_id, },
                        CharacterItemsStorageCounter { player, count: storageCounter.count },
                    )
                );
            }

            emit!(
                world,
                (BuyItem {
                    player,
                    itemId: item_id,
                    cost: item.price,
                    itemRarity: item.rarity,
                    birthCount: player_char.birthCount
                })
            );

            set!(world, (player_char, shop_data));
        }


        fn sell_item(world: IWorldDispatcher, storage_item_id: u32) {
            let player = get_caller_address();

            let mut storageItem = get!(world, (player, storage_item_id), (CharacterItemStorage));
            let itemId = storageItem.itemId;
            assert(itemId != 0, 'invalid item_id');

            let mut item = get!(world, itemId, (Item));
            let mut playerChar = get!(world, player, (Character));

            let itemPrice = item.price;
            let sellPrice = itemPrice / 2;

            storageItem.itemId = 0;

            playerChar.gold += sellPrice;

            emit!(
                world,
                (SellItem {
                    player,
                    itemId: itemId,
                    price: sellPrice,
                    itemRarity: item.rarity,
                    birthCount: playerChar.birthCount
                })
            );

            set!(world, (storageItem, playerChar));
        }

        fn reroll_shop(world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));
            assert(char.gold >= 1, 'Not enough gold');

            let mut shop = get!(world, player, (Shop));

            // TODO: Will move these arrays after Dojo supports storing array
            let mut common: Array<usize> = ArrayTrait::new();
            let mut commonSize: usize = 0;
            let mut uncommon: Array<usize> = ArrayTrait::new();
            let mut uncommonSize: usize = 0;
            let mut rare: Array<usize> = ArrayTrait::new();
            let mut rareSize: usize = 0;

            let itemsCounter = get!(world, ITEMS_COUNTER_ID, ItemsCounter);
            let mut count = itemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let item = get!(world, count, (Item));

                if item.id == 14 || item.id == 18 || item.id == 19 || item.id == 22 {
                    count -= 1;
                    continue;
                }

                let rarity: felt252 = item.rarity.into();
                match rarity {
                    0 => {},
                    1 => {
                        common.append(count);
                        commonSize += 1;
                    },
                    2 => {
                        uncommon.append(count);
                        uncommonSize += 1;
                    },
                    3 => {
                        rare.append(count);
                        rareSize += 1;
                    },
                    _ => {}
                }

                count -= 1;
            };

            assert(commonSize > 0, 'No common items found');

            let (seed1, seed2, seed3, seed4) = pseudo_seed();

            let mut rareFlag = false;
            // common: 70%, uncommon: 30%, rare: 10%
            let mut random_index = 0;
            if char.wins < 3 {
                random_index = random(seed1, 90);
            } else {
                random_index = random(seed1, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed1, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed1, 90);
            }

            if random_index < 70 {
                // commonSize is always greater than 0
                random_index = random(seed1, commonSize);
                shop.item1 = *common.at(random_index);
            } else if random_index < 90 {
                // uncommonSize is always greater than 0
                random_index = random(seed1, uncommonSize);
                shop.item1 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                // rareSize is always greater than 0
                random_index = random(seed1, rareSize);
                shop.item1 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed2, 90);
            } else {
                random_index = random(seed2, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed2, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed2, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed2, commonSize);
                shop.item2 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed2, uncommonSize);
                shop.item2 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                random_index = random(seed2, rareSize);
                shop.item2 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed3, 90);
            } else {
                random_index = random(seed3, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed3, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed3, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed3, commonSize);
                shop.item3 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed3, uncommonSize);
                shop.item3 = *uncommon.at(random_index);

                rareFlag = true;
            } else {
                random_index = random(seed3, rareSize);
                shop.item3 = *rare.at(random_index);

                rareFlag = true;
            }

            if char.wins < 3 {
                random_index = random(seed4, 90);
            } else {
                random_index = random(seed4, 100);
            }
            if uncommonSize == 0 {
                random_index = random(seed4, 70);
            } else if rareSize == 0 && uncommonSize > 0 {
                random_index = random(seed4, 90);
            }

            if random_index < 70 || rareFlag {
                random_index = random(seed4, commonSize);
                shop.item4 = *common.at(random_index);
            } else if random_index < 90 {
                random_index = random(seed4, uncommonSize);
                shop.item4 = *uncommon.at(random_index);
            } else {
                random_index = random(seed4, rareSize);
                shop.item4 = *rare.at(random_index);
            }

            char.gold -= 1;

            set!(world, (shop, char));
        }


        fn is_world_owner(world: IWorldDispatcher, player: ContractAddress) -> bool {
            // resource id of world is 0
            let is_owner = world.is_owner(player, 0);

            is_owner
        }

        fn is_item_owned(world: IWorldDispatcher, player: ContractAddress, id: usize) -> bool {
            let storageItem = get!(world, (player, id), (CharacterItemStorage));

            if storageItem.itemId == 0 {
                return false;
            }

            true
        }

        fn fight(world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.dummied == true, 'dummy not created');
            assert(char.loss < 5, 'max loss reached');

            let (seed1, seed2, _, _) = pseudo_seed();
            let dummyCharCounter = get!(world, char.wins, (DummyCharacterCounter));
            assert(dummyCharCounter.count > 1, 'only self dummy created');

            let random_index = random(seed1, dummyCharCounter.count) + 1;
            let mut dummy_index = random_index;
            let mut dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);

            while dummyChar.player == player {
                dummy_index = dummy_index % dummyCharCounter.count + 1;
                assert(dummy_index != random_index, 'no others dummy found');
                dummyChar = get!(world, (char.wins, dummy_index), DummyCharacter);
            };

            // start the battle
            let mut char_health: usize = char.health;
            let char_health_flag: usize = char.health;
            let mut dummy_health: usize = dummyChar.health;
            let dummy_health_flag: usize = dummyChar.health;

            let mut char_items_len: usize = 0;
            let mut dummy_items_len: usize = 0;

            // =========  buffs/debuffs stacks ========= 
            let mut char_armor: usize = 0;
            let mut dummy_armor: usize = 0;

            let mut char_regen: usize = 0;
            let mut dummy_regen: usize = 0;

            let mut char_reflect: usize = 0;
            let mut dummy_reflect: usize = 0;

            let mut char_empower: usize = 0;
            let mut dummy_empower: usize = 0;

            let mut char_poison: usize = 0;
            let mut dummy_poison: usize = 0;

            let mut char_on_hit_items = ArrayTrait::new();
            let mut dummy_on_hit_items = ArrayTrait::new();
            // =========  end =========

            // sort items
            let mut items: Felt252Dict<u32> = Default::default();
            let mut item_belongs: Felt252Dict<felt252> = Default::default();
            let mut items_length: usize = 0;

            let inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut inventoryItemCount = inventoryItemsCounter.count;

            loop {
                if inventoryItemCount == 0 {
                    break;
                }
                let charItem = get!(world, (player, inventoryItemCount), (CharacterItemInventory));
                let item = get!(world, charItem.itemId, (Item));
                if item.itemType == 4 {
                    inventoryItemCount -= 1;
                    continue;
                }
                let cooldown = item.cooldown;
                if cooldown > 0 {
                    items.insert(items_length.into(), charItem.itemId);
                    item_belongs.insert(items_length.into(), 'player');

                    items_length += 1;
                    char_items_len += 1;
                } else if cooldown == 0 {
                    // ====== on start to plus stacks, 100% chance ======
                    // buff
                    if item.armorActivation == 1 {
                        char_armor += item.armor;
                    }
                    if item.regenActivation == 1 {
                        char_regen += item.regen;
                    }
                    if item.reflectActivation == 1 {
                        char_reflect += item.reflect;
                    }
                    if item.empowerActivation == 1 {
                        char_empower += item.empower;
                    }
                    // debuff
                    if item.poisonActivation == 1 {
                        dummy_poison += item.poison;
                    }
                // ====== end ======
                }

                // ====== on hit to plus stacks ======
                if item.armorActivation == 2 {
                    char_on_hit_items.append((EFFECT_ARMOR, item.chance, item.armor));
                }
                if item.regenActivation == 2 {
                    char_on_hit_items.append((EFFECT_REGEN, item.chance, item.regen));
                }
                if item.reflectActivation == 2 {
                    char_on_hit_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                }
                if item.empowerActivation == 2 {
                    char_on_hit_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                }
                if item.poisonActivation == 2 {
                    char_on_hit_items.append((EFFECT_POISON, item.chance, item.poison));
                }
                // ====== end ======

                inventoryItemCount -= 1;
            };
            let char_on_hit_items_span = char_on_hit_items.span();

            let dummyCharItemsCounter = get!(
                world, (char.wins, dummy_index), (DummyCharacterItemsCounter)
            );
            let mut dummy_item_count = dummyCharItemsCounter.count;
            loop {
                if dummy_item_count == 0 {
                    break;
                }

                let dummy_item = get!(
                    world, (char.wins, dummy_index, dummy_item_count), (DummyCharacterItem)
                );
                let item = get!(world, dummy_item.itemId, (Item));
                if item.itemType == 4 {
                    dummy_item_count -= 1;
                    continue;
                }
                if item.cooldown > 0 {
                    items.insert(items_length.into(), dummy_item.itemId);
                    item_belongs.insert(items_length.into(), 'dummy');

                    items_length += 1;
                    dummy_items_len += 1;
                } else if item.cooldown == 0 {
                    // ====== on start to plus stacks, 100% chance ======
                    // buff
                    if item.armorActivation == 1 {
                        dummy_armor += item.armor;
                    }
                    if item.regenActivation == 1 {
                        dummy_regen += item.regen;
                    }
                    if item.reflectActivation == 1 {
                        dummy_reflect += item.reflect;
                    }
                    if item.empowerActivation == 1 {
                        dummy_empower += item.empower;
                    }
                    // debuff
                    if item.poisonActivation == 1 {
                        char_poison += item.poison;
                    }
                // ====== end ======
                }

                // ====== on hit to plus stacks ======
                if item.armorActivation == 2 {
                    dummy_on_hit_items.append((EFFECT_ARMOR, item.chance, item.armor));
                }
                if item.regenActivation == 2 {
                    dummy_on_hit_items.append((EFFECT_REGEN, item.chance, item.regen));
                }
                if item.reflectActivation == 2 {
                    dummy_on_hit_items.append((EFFECT_REFLECT, item.chance, item.reflect));
                }
                if item.empowerActivation == 2 {
                    dummy_on_hit_items.append((EFFECT_EMPOWER, item.chance, item.empower));
                }
                if item.poisonActivation == 2 {
                    dummy_on_hit_items.append((EFFECT_POISON, item.chance, item.poison));
                }
                // ====== end ======

                dummy_item_count -= 1;
            };
            let dummy_on_hit_items_span = dummy_on_hit_items.span();

            // sorting items based on cooldown in ascending order
            let mut i: usize = 0;
            let mut j: usize = 0;
            loop {
                if i >= items_length {
                    break;
                }
                loop {
                    if j >= (items_length - i - 1) {
                        break;
                    }

                    // fetch respective itemids
                    let items_at_j = items.get(j.into());
                    let items_at_j_belongs = item_belongs.get(j.into());
                    let items_at_j_plus_one = items.get((j + 1).into());
                    let items_at_j_plus_one_belongs = item_belongs.get((j + 1).into());

                    //fetch itemid data
                    let item_data_at_j = get!(world, items_at_j, Item);
                    let item_data_at_j_plus_one = get!(world, items_at_j_plus_one, Item);

                    if item_data_at_j.cooldown > item_data_at_j_plus_one.cooldown {
                        items.insert(j.into(), items_at_j_plus_one);
                        item_belongs.insert(j.into(), items_at_j_plus_one_belongs);
                        items.insert((j + 1).into(), items_at_j);
                        item_belongs.insert((j + 1).into(), items_at_j_belongs);
                    }

                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // record the battle log
            let mut battleLogCounter = get!(world, player, (BattleLogCounter));
            battleLogCounter.count += 1;
            let battleLogCounterCount = battleLogCounter.count;

            let mut battleLogsCount = 0;

            // battle logic
            let mut seconds = 0;
            let mut winner = '';

            let mut rand = 0;
            let mut v = 0;

            emit!(
                world,
                (BattleLogDetail {
                    player,
                    battleLogId: battleLogCounterCount,
                    id: battleLogsCount,
                    whoTriggered: 0,
                    whichItem: 0,
                    damageCaused: 0,
                    isDodged: false,
                    cleansePoison: 0,
                    buffType: 0,
                    regenHP: 0,
                    player_remaining_health: char_health,
                    dummy_remaining_health: dummy_health,
                    player_armor_stacks: char_armor,
                    player_regen_stacks: char_regen,
                    player_reflect_stacks: char_reflect,
                    player_empower_stacks: char_empower,
                    player_poison_stacks: char_poison,
                    dummy_armor_stacks: dummy_armor,
                    dummy_regen_stacks: dummy_regen,
                    dummy_reflect_stacks: dummy_reflect,
                    dummy_empower_stacks: dummy_empower,
                    dummy_poison_stacks: dummy_poison,
                })
            );

            loop {
                seconds += 1;
                if seconds >= 25_u8 {
                    if char_health <= dummy_health {
                        winner = 'dummy';
                    } else {
                        winner = 'player';
                    }
                    break;
                }

                let mut i: usize = 0;

                loop {
                    if i == items_length {
                        break;
                    }

                    let curr_item_index = items.get(i.into());
                    let curr_item_belongs = item_belongs.get(i.into());

                    let curr_item_data = get!(world, curr_item_index, (Item));

                    let mut damage = curr_item_data.damage;
                    if curr_item_data.itemType == 1 {
                        if curr_item_belongs == 'player' && char_empower > 0 {
                            damage += char_empower;
                        } else if curr_item_belongs == 'dummy' && dummy_empower > 0 {
                            damage += dummy_empower;
                        }
                    }

                    let cleansePoison = curr_item_data.cleansePoison;
                    let chance = curr_item_data.chance;
                    let cooldown = curr_item_data.cooldown;

                    // each second is treated as 1 unit of cooldown 
                    if seconds % cooldown == 0 {
                        v += seconds.into();
                        rand = random(seed2 + v, 100);
                        if rand < chance {
                            if curr_item_belongs == 'player' {
                                // ====== on cooldown to plus stacks, all use the same randomness ======
                                if curr_item_data.armorActivation == 3 {
                                    char_armor += curr_item_data.armor;
                                }
                                if curr_item_data.regenActivation == 3 {
                                    char_regen += curr_item_data.regen;
                                }
                                if curr_item_data.reflectActivation == 3 {
                                    char_reflect += curr_item_data.reflect;
                                }
                                if curr_item_data.empowerActivation == 3 {
                                    char_empower += curr_item_data.empower;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    dummy_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if damage > 0 {
                                    // ====== Armor: used to absorb damage ======
                                    let mut damageCaused = 0;
                                    if damage <= dummy_armor {
                                        dummy_armor -= damage;
                                    } else {
                                        damageCaused = damage - dummy_armor;
                                        dummy_armor = 0;
                                    }
                                    // ====== end ======

                                    if dummy_health <= damageCaused {
                                        dummy_health = 0;
                                    } else {
                                        dummy_health -= damageCaused;
                                    }

                                    battleLogsCount += 1;
                                    emit!(
                                        world,
                                        (BattleLogDetail {
                                            player,
                                            battleLogId: battleLogCounterCount,
                                            id: battleLogsCount,
                                            whoTriggered: curr_item_belongs,
                                            whichItem: curr_item_index,
                                            damageCaused: damageCaused,
                                            isDodged: false,
                                            cleansePoison: 0,
                                            buffType: EFFECT_ARMOR,
                                            regenHP: 0,
                                            player_remaining_health: char_health,
                                            dummy_remaining_health: dummy_health,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if dummy_health == 0 {
                                        winner = 'player';
                                        break;
                                    }

                                    // ====== dummy get hit, to plus stacks ======
                                    let mut on_hit_items_len = dummy_on_hit_items_span.len();
                                    loop {
                                        if on_hit_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_hit_item_type, on_hit_item_chance, on_hit_item_stack
                                        ) =
                                            *dummy_on_hit_items_span
                                            .at(on_hit_items_len - 1);

                                        if rand < on_hit_item_chance {
                                            if on_hit_item_type == EFFECT_ARMOR {
                                                dummy_armor += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REGEN {
                                                dummy_regen += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REFLECT {
                                                dummy_reflect += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_EMPOWER {
                                                dummy_empower += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                char_poison += on_hit_item_stack;
                                            }
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                    if curr_item_data.itemType == 1 && dummy_reflect > 0 {
                                        damageCaused = 0;
                                        let mut reflect_damage = dummy_reflect;
                                        if reflect_damage > damage {
                                            reflect_damage = damage;
                                        }

                                        // ====== Armor: used to absorb damage ======
                                        if reflect_damage <= char_armor {
                                            char_armor -= reflect_damage;
                                        } else {
                                            damageCaused = reflect_damage - char_armor;
                                            char_armor = 0;
                                        }
                                        // ====== end ======

                                        if char_health <= damageCaused {
                                            char_health = 0;
                                        } else {
                                            char_health -= damageCaused;
                                        }

                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: 'dummy',
                                                whichItem: 0,
                                                damageCaused: damageCaused,
                                                isDodged: false,
                                                cleansePoison: 0,
                                                buffType: EFFECT_REFLECT,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );

                                        if char_health == 0 {
                                            winner = 'dummy';
                                            break;
                                        }
                                    }
                                // ====== end ======
                                } else {
                                    if cleansePoison > 0 {
                                        if char_poison > cleansePoison {
                                            char_poison -= cleansePoison;
                                        } else {
                                            char_poison = 0;
                                        }
                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: curr_item_belongs,
                                                whichItem: curr_item_index,
                                                damageCaused: 0,
                                                cleansePoison: cleansePoison,
                                                isDodged: false,
                                                buffType: EFFECT_CLEANSE_POISON,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );
                                    }
                                }
                            } else {
                                // ====== on cooldown to plus stacks, all use the same randomness ======
                                if curr_item_data.armorActivation == 3 {
                                    dummy_armor += curr_item_data.armor;
                                }
                                if curr_item_data.regenActivation == 3 {
                                    dummy_regen += curr_item_data.regen;
                                }
                                if curr_item_data.reflectActivation == 3 {
                                    dummy_reflect += curr_item_data.reflect;
                                }
                                if curr_item_data.empowerActivation == 3 {
                                    dummy_empower += curr_item_data.empower;
                                }
                                if curr_item_data.poisonActivation == 3 {
                                    char_poison += curr_item_data.poison;
                                }
                                // ====== end ======

                                if damage > 0 {
                                    // ====== Armor: used to absorb damage ======
                                    let mut damageCaused = 0;
                                    if damage <= char_armor {
                                        char_armor -= damage;
                                    } else {
                                        damageCaused = damage - char_armor;
                                        char_armor = 0;
                                    }
                                    // ====== end ======

                                    if char_health <= damageCaused {
                                        char_health = 0;
                                    } else {
                                        char_health -= damageCaused;
                                    }

                                    battleLogsCount += 1;
                                    emit!(
                                        world,
                                        (BattleLogDetail {
                                            player,
                                            battleLogId: battleLogCounterCount,
                                            id: battleLogsCount,
                                            whoTriggered: curr_item_belongs,
                                            whichItem: curr_item_index,
                                            damageCaused: damageCaused,
                                            isDodged: false,
                                            cleansePoison: 0,
                                            buffType: EFFECT_ARMOR,
                                            regenHP: 0,
                                            player_remaining_health: char_health,
                                            dummy_remaining_health: dummy_health,
                                            player_armor_stacks: char_armor,
                                            player_regen_stacks: char_regen,
                                            player_reflect_stacks: char_reflect,
                                            player_empower_stacks: char_empower,
                                            player_poison_stacks: char_poison,
                                            dummy_armor_stacks: dummy_armor,
                                            dummy_regen_stacks: dummy_regen,
                                            dummy_reflect_stacks: dummy_reflect,
                                            dummy_empower_stacks: dummy_empower,
                                            dummy_poison_stacks: dummy_poison,
                                        })
                                    );

                                    if char_health == 0 {
                                        winner = 'dummy';
                                        break;
                                    }

                                    // ====== char get hit, to plus stacks ======
                                    let mut on_hit_items_len = char_on_hit_items_span.len();
                                    loop {
                                        if on_hit_items_len == 0 {
                                            break;
                                        }

                                        let (
                                            on_hit_item_type, on_hit_item_chance, on_hit_item_stack
                                        ) =
                                            *char_on_hit_items_span
                                            .at(on_hit_items_len - 1);

                                        if rand < on_hit_item_chance {
                                            if on_hit_item_type == EFFECT_ARMOR {
                                                char_armor += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REGEN {
                                                char_regen += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_REFLECT {
                                                char_reflect += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_EMPOWER {
                                                char_empower += on_hit_item_stack;
                                            } else if on_hit_item_type == EFFECT_POISON {
                                                dummy_poison += on_hit_item_stack;
                                            }
                                        }

                                        on_hit_items_len -= 1;
                                    };
                                    // ====== end ======

                                    // ====== Reflect effect: Deals 1 damage per stack when hit with a Melee weapon (up to 100% of the damage). ======
                                    if curr_item_data.itemType == 1 && char_reflect > 0 {
                                        damageCaused = 0;
                                        let mut reflect_damage = char_reflect;
                                        if reflect_damage > damage {
                                            reflect_damage = damage;
                                        }

                                        // ====== Armor: used to absorb damage ======
                                        if reflect_damage <= dummy_armor {
                                            dummy_armor -= reflect_damage;
                                        } else {
                                            damageCaused = reflect_damage - dummy_armor;
                                            dummy_armor = 0;
                                        }
                                        // ====== end ======

                                        if dummy_health <= damageCaused {
                                            dummy_health = 0;
                                        } else {
                                            dummy_health -= damageCaused;
                                        }

                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: 'player',
                                                whichItem: 0,
                                                damageCaused: damageCaused,
                                                isDodged: false,
                                                cleansePoison: 0,
                                                buffType: EFFECT_REFLECT,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );

                                        if dummy_health == 0 {
                                            winner = 'player';
                                            break;
                                        }
                                    }
                                // ====== end ======
                                } else {
                                    if cleansePoison > 0 {
                                        if dummy_poison > cleansePoison {
                                            dummy_poison -= cleansePoison;
                                        } else {
                                            dummy_poison = 0;
                                        }
                                        battleLogsCount += 1;
                                        emit!(
                                            world,
                                            (BattleLogDetail {
                                                player,
                                                battleLogId: battleLogCounterCount,
                                                id: battleLogsCount,
                                                whoTriggered: curr_item_belongs,
                                                whichItem: curr_item_index,
                                                damageCaused: 0,
                                                isDodged: false,
                                                cleansePoison: cleansePoison,
                                                buffType: EFFECT_CLEANSE_POISON,
                                                regenHP: 0,
                                                player_remaining_health: char_health,
                                                dummy_remaining_health: dummy_health,
                                                player_armor_stacks: char_armor,
                                                player_regen_stacks: char_regen,
                                                player_reflect_stacks: char_reflect,
                                                player_empower_stacks: char_empower,
                                                player_poison_stacks: char_poison,
                                                dummy_armor_stacks: dummy_armor,
                                                dummy_regen_stacks: dummy_regen,
                                                dummy_reflect_stacks: dummy_reflect,
                                                dummy_empower_stacks: dummy_empower,
                                                dummy_poison_stacks: dummy_poison,
                                            })
                                        );
                                    }
                                }
                            }
                        } else if rand >= chance && damage > 0 {
                            battleLogsCount += 1;
                            emit!(
                                world,
                                (BattleLogDetail {
                                    player,
                                    battleLogId: battleLogCounterCount,
                                    id: battleLogsCount,
                                    whoTriggered: curr_item_belongs,
                                    whichItem: curr_item_index,
                                    damageCaused: 0,
                                    isDodged: true,
                                    cleansePoison: 0,
                                    buffType: 0,
                                    regenHP: 0,
                                    player_remaining_health: char_health,
                                    dummy_remaining_health: dummy_health,
                                    player_armor_stacks: char_armor,
                                    player_regen_stacks: char_regen,
                                    player_reflect_stacks: char_reflect,
                                    player_empower_stacks: char_empower,
                                    player_poison_stacks: char_poison,
                                    dummy_armor_stacks: dummy_armor,
                                    dummy_regen_stacks: dummy_regen,
                                    dummy_reflect_stacks: dummy_reflect,
                                    dummy_empower_stacks: dummy_empower,
                                    dummy_poison_stacks: dummy_poison,
                                })
                            );
                        }
                    }

                    i += 1;
                };

                // ====== Poison effect: Deals 1 damage per stack every 2 seconds. ======
                // ====== Heal effect: Regenerate 1 health per stack every 2 seconds. ======
                if seconds % 2 == 0 {
                    if char_poison > 0 {
                        if char_health <= char_poison {
                            char_health = 0;
                        } else {
                            char_health -= char_poison;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'dummy',
                                whichItem: 0,
                                damageCaused: char_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if char_health == 0 {
                            winner = 'dummy';
                            break;
                        }
                    }
                    if dummy_poison > 0 {
                        if dummy_health <= dummy_poison {
                            dummy_health = 0;
                        } else {
                            dummy_health -= dummy_poison;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'player',
                                whichItem: 0,
                                damageCaused: dummy_poison,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_POISON,
                                regenHP: 0,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );

                        if dummy_health == 0 {
                            winner = 'player';
                            break;
                        }
                    }
                    if char_regen > 0 {
                        char_health += char_regen;
                        if char_health > char_health_flag {
                            char_health = char_health_flag;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'player',
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: char_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );
                    }
                    if dummy_regen > 0 {
                        dummy_health += dummy_regen;
                        if dummy_health > dummy_health_flag {
                            dummy_health = dummy_health_flag;
                        }

                        battleLogsCount += 1;
                        emit!(
                            world,
                            (BattleLogDetail {
                                player,
                                battleLogId: battleLogCounterCount,
                                id: battleLogsCount,
                                whoTriggered: 'dummy',
                                whichItem: 0,
                                damageCaused: 0,
                                isDodged: false,
                                cleansePoison: 0,
                                buffType: EFFECT_REGEN,
                                regenHP: dummy_regen,
                                player_remaining_health: char_health,
                                dummy_remaining_health: dummy_health,
                                player_armor_stacks: char_armor,
                                player_regen_stacks: char_regen,
                                player_reflect_stacks: char_reflect,
                                player_empower_stacks: char_empower,
                                player_poison_stacks: char_poison,
                                dummy_armor_stacks: dummy_armor,
                                dummy_regen_stacks: dummy_regen,
                                dummy_reflect_stacks: dummy_reflect,
                                dummy_empower_stacks: dummy_empower,
                                dummy_poison_stacks: dummy_poison,
                            })
                        );
                    }
                }
                // ====== end ======

                if winner != '' {
                    break;
                }
            };

            let battleLog = BattleLog {
                player: player,
                id: battleLogCounter.count,
                dummyCharLevel: char.wins,
                dummyCharId: dummy_index,
                winner: winner,
                seconds: seconds,
            };
            set!(world, (battleLogCounter, battleLog));

            if winner == 'player' {
                char.wins += 1;
                char.totalWins += 1;
                char.winStreak += 1;
                char.dummied = false;
                char.gold += 5;
                if char.wins < 5 {
                    char.health += 10;
                } else if char.wins == 5 {
                    char.health += 15;
                }

                char.rating += 25;

                if (dummyChar.rating < 10) {
                    dummyChar.rating = 0;
                } else {
                    dummyChar.rating -= 10;
                }
            } else {
                char.loss += 1;
                char.totalLoss += 1;
                char.winStreak = 0;
                char.gold += 5;

                dummyChar.rating += 25;

                if (char.rating < 10) {
                    char.rating = 0;
                } else {
                    char.rating -= 10;
                }
            }
            char.updatedAt = get_block_timestamp();
            set!(world, (char, dummyChar));
        }

        fn create_dummy(world: IWorldDispatcher) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.dummied == false, 'dummy already created');
            assert(char.loss < 5, 'max loss reached');

            let mut dummyCharCounter = get!(world, char.wins, (DummyCharacterCounter));
            dummyCharCounter.count += 1;

            let dummyChar = DummyCharacter {
                level: char.wins,
                id: dummyCharCounter.count,
                name: char.name,
                wmClass: char.wmClass,
                health: char.health,
                player: player,
                rating: char.rating,
            };
            char.dummied = true;

            let inventoryItemCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryItemCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let inventoryItem = get!(world, (player, count), (CharacterItemInventory));

                let mut dummyCharItemsCounter = get!(
                    world, (char.wins, dummyCharCounter.count), (DummyCharacterItemsCounter)
                );
                dummyCharItemsCounter.count += 1;

                let dummyCharItem = DummyCharacterItem {
                    level: char.wins,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: inventoryItem.itemId,
                    position: inventoryItem.position,
                    rotation: inventoryItem.rotation,
                };

                set!(world, (dummyCharItemsCounter, dummyCharItem));

                count -= 1;
            };

            set!(world, (char, dummyCharCounter, dummyChar));
        }

        fn rebirth(world: IWorldDispatcher, name: felt252, wmClass: WMClass) {
            let player = get_caller_address();

            let mut char = get!(world, player, (Character));

            assert(char.loss >= 5, 'loss not reached');

            // To allow others to use the player's privous name
            if char.name != name {
                let mut nameRecord = get!(world, char.name, NameRecord);
                nameRecord.player = starknet::contract_address_const::<0>();
                set!(world, (nameRecord));
            }

            // required to calling spawn doesn't fail
            char.name = '';

            let mut inventoryItemsCounter = get!(world, player, (CharacterItemsInventoryCounter));
            let mut count = inventoryItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut inventoryItem = get!(world, (player, count), (CharacterItemInventory));

                inventoryItem.itemId = 0;
                inventoryItem.position.x = 0;
                inventoryItem.position.y = 0;
                inventoryItem.rotation = 0;

                set!(world, (inventoryItem));

                count -= 1;
            };

            let mut storageItemsCounter = get!(world, player, (CharacterItemsStorageCounter));
            let mut count = storageItemsCounter.count;

            loop {
                if count == 0 {
                    break;
                }

                let mut storageItem = get!(world, (player, count), (CharacterItemStorage));

                storageItem.itemId = 0;

                set!(world, (storageItem));

                count -= 1;
            };

            // clear BackpackGrids
            let mut i = 0;
            let mut j = 0;
            loop {
                if i >= GRID_X {
                    break;
                }
                loop {
                    if j >= GRID_Y {
                        break;
                    }

                    let player_backpack_grid_data = get!(world, (player, i, j), (BackpackGrids));

                    if player_backpack_grid_data.occupied || player_backpack_grid_data.enabled {
                        set!(
                            world,
                            (BackpackGrids {
                                player: player, x: i, y: j, enabled: false, occupied: false
                            })
                        );
                    }
                    j += 1;
                };
                j = 0;
                i += 1;
            };

            // clear shop
            let mut shop = get!(world, player, (Shop));
            shop.item1 = 0;
            shop.item2 = 0;
            shop.item3 = 0;
            shop.item4 = 0;

            inventoryItemsCounter.count = 0;
            storageItemsCounter.count = 0;
            set!(world, (char, shop, inventoryItemsCounter, storageItemsCounter));

            self.spawn(name, wmClass);
        }

        fn prefine_dummy(world: IWorldDispatcher, level: usize) {
            let player = get_caller_address();
            assert(self.is_world_owner(player), 'player not world owner');

            let mut name: felt252 = '';
            let mut wmClassNo: u8 = 0;
            let mut wmClass: WMClass = WMClass::Warrior;
            let mut health: usize = 0;

            let mut items: Array<PredefinedItem> = array![];

            match level {
                0 => {
                    name = Dummy0::name;
                    wmClassNo = Dummy0::wmClass;
                    health = Dummy0::health;
                    items = Dummy0::get_items();
                },
                1 => {
                    name = Dummy1::name;
                    wmClassNo = Dummy1::wmClass;
                    health = Dummy1::health;
                    items = Dummy1::get_items();
                },
                _ => {
                    assert(false, 'invalid level');
                }
            }

            match wmClassNo {
                0 => {
                    wmClass = WMClass::Warrior;
                },
                1 => {
                    wmClass = WMClass::Warlock;
                },
                _ => {
                    assert(false, 'invalid wmClass');
                }
            }


            let mut dummyCharCounter = get!(world, level, (DummyCharacterCounter));
            dummyCharCounter.count += 1;

            let dummyChar = DummyCharacter {
                level: level,
                id: dummyCharCounter.count,
                name: name,
                wmClass: wmClass,
                health: health,
                player: starknet::contract_address_const::<0x0>(),
                rating: 0,
            };

            let mut dummyCharItemsCounter = get!(
                world, (level, dummyCharCounter.count), (DummyCharacterItemsCounter)
            );

            loop {
                if items.len() == 0 {
                    break;
                }

                let item = items.pop_front().unwrap();

                dummyCharItemsCounter.count += 1;

                let dummyCharItem = DummyCharacterItem {
                    level: level,
                    dummyCharId: dummyCharCounter.count,
                    counterId: dummyCharItemsCounter.count,
                    itemId: item.itemId,
                    position: item.position,
                    rotation: item.rotation,
                };

                set!(world, (dummyCharItem));
            };

            set!(world, (dummyCharCounter, dummyChar, dummyCharItemsCounter));
        }
    }
}
