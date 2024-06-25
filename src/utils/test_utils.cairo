use warpack_masters::{systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}}};
use warpack_masters::{items};


fn add_items(ref actions_system: IActionsDispatcher) {
    actions_system
        .add_item(
            items::Backpack1::id,
            items::Backpack1::name,
            items::Backpack1::itemType,
            items::Backpack1::width,
            items::Backpack1::height,
            items::Backpack1::price,
            items::Backpack1::damage,
            items::Backpack1::cleansePoison,
            items::Backpack1::chance,
            items::Backpack1::cooldown,
            items::Backpack1::rarity,
            items::Backpack1::armor,
            items::Backpack1::armorActivation,
            items::Backpack1::regen,
            items::Backpack1::regenActivation,
            items::Backpack1::reflect,
            items::Backpack1::reflectActivation,
            items::Backpack1::poison,
            items::Backpack1::poisonActivation,
            items::Backpack1::empower,
            items::Backpack1::empowerActivation,
        );

    actions_system
        .add_item(
            items::Backpack2::id,
            items::Backpack2::name,
            items::Backpack2::itemType,
            items::Backpack2::width,
            items::Backpack2::height,
            items::Backpack2::price,
            items::Backpack2::damage,
            items::Backpack2::cleansePoison,
            items::Backpack2::chance,
            items::Backpack2::cooldown,
            items::Backpack2::rarity,
            items::Backpack2::armor,
            items::Backpack2::armorActivation,
            items::Backpack2::regen,
            items::Backpack2::regenActivation,
            items::Backpack2::reflect,
            items::Backpack2::reflectActivation,
            items::Backpack2::poison,
            items::Backpack2::poisonActivation,
            items::Backpack2::empower,
            items::Backpack2::empowerActivation,
        );

    actions_system
        .add_item(
            items::Dagger::id,
            items::Dagger::name,
            items::Dagger::itemType,
            items::Dagger::width,
            items::Dagger::height,
            items::Dagger::price,
            items::Dagger::damage,
            items::Dagger::cleansePoison,
            items::Dagger::chance,
            items::Dagger::cooldown,
            items::Dagger::rarity,
            items::Dagger::armor,
            items::Dagger::armorActivation,
            items::Dagger::regen,
            items::Dagger::regenActivation,
            items::Dagger::reflect,
            items::Dagger::reflectActivation,
            items::Dagger::poison,
            items::Dagger::poisonActivation,
            items::Dagger::empower,
            items::Dagger::empowerActivation,
        );

    actions_system
        .add_item(
            items::Sword::id,
            items::Sword::name,
            items::Sword::itemType,
            items::Sword::width,
            items::Sword::height,
            items::Sword::price,
            items::Sword::damage,
            items::Sword::cleansePoison,
            items::Sword::chance,
            items::Sword::cooldown,
            items::Sword::rarity,
            items::Sword::armor,
            items::Sword::armorActivation,
            items::Sword::regen,
            items::Sword::regenActivation,
            items::Sword::reflect,
            items::Sword::reflectActivation,
            items::Sword::poison,
            items::Sword::poisonActivation,
            items::Sword::empower,
            items::Sword::empowerActivation,
        );

    actions_system
        .add_item(
            items::Spike::id,
            items::Spike::name,
            items::Spike::itemType,
            items::Spike::width,
            items::Spike::height,
            items::Spike::price,
            items::Spike::damage,
            items::Spike::cleansePoison,
            items::Spike::chance,
            items::Spike::cooldown,
            items::Spike::rarity,
            items::Spike::armor,
            items::Spike::armorActivation,
            items::Spike::regen,
            items::Spike::regenActivation,
            items::Spike::reflect,
            items::Spike::reflectActivation,
            items::Spike::poison,
            items::Spike::poisonActivation,
            items::Spike::empower,
            items::Spike::empowerActivation,
        );

    actions_system
        .add_item(
            items::Shield::id,
            items::Shield::name,
            items::Shield::itemType,
            items::Shield::width,
            items::Shield::height,
            items::Shield::price,
            items::Shield::damage,
            items::Shield::cleansePoison,
            items::Shield::chance,
            items::Shield::cooldown,
            items::Shield::rarity,
            items::Shield::armor,
            items::Shield::armorActivation,
            items::Shield::regen,
            items::Shield::regenActivation,
            items::Shield::reflect,
            items::Shield::reflectActivation,
            items::Shield::poison,
            items::Shield::poisonActivation,
            items::Shield::empower,
            items::Shield::empowerActivation,
        );

    actions_system
        .add_item(
            items::Helmet::id,
            items::Helmet::name,
            items::Helmet::itemType,
            items::Helmet::width,
            items::Helmet::height,
            items::Helmet::price,
            items::Helmet::damage,
            items::Helmet::cleansePoison,
            items::Helmet::chance,
            items::Helmet::cooldown,
            items::Helmet::rarity,
            items::Helmet::armor,
            items::Helmet::armorActivation,
            items::Helmet::regen,
            items::Helmet::regenActivation,
            items::Helmet::reflect,
            items::Helmet::reflectActivation,
            items::Helmet::poison,
            items::Helmet::poisonActivation,
            items::Helmet::empower,
            items::Helmet::empowerActivation,
        );

    actions_system
        .add_item(
            items::HealingPotion::id,
            items::HealingPotion::name,
            items::HealingPotion::itemType,
            items::HealingPotion::width,
            items::HealingPotion::height,
            items::HealingPotion::price,
            items::HealingPotion::damage,
            items::HealingPotion::cleansePoison,
            items::HealingPotion::chance,
            items::HealingPotion::cooldown,
            items::HealingPotion::rarity,
            items::HealingPotion::armor,
            items::HealingPotion::armorActivation,
            items::HealingPotion::regen,
            items::HealingPotion::regenActivation,
            items::HealingPotion::reflect,
            items::HealingPotion::reflectActivation,
            items::HealingPotion::poison,
            items::HealingPotion::poisonActivation,
            items::HealingPotion::empower,
            items::HealingPotion::empowerActivation,
        );

    actions_system
        .add_item(
            items::LeatherArmor::id,
            items::LeatherArmor::name,
            items::LeatherArmor::itemType,
            items::LeatherArmor::width,
            items::LeatherArmor::height,
            items::LeatherArmor::price,
            items::LeatherArmor::damage,
            items::LeatherArmor::cleansePoison,
            items::LeatherArmor::chance,
            items::LeatherArmor::cooldown,
            items::LeatherArmor::rarity,
            items::LeatherArmor::armor,
            items::LeatherArmor::armorActivation,
            items::LeatherArmor::regen,
            items::LeatherArmor::regenActivation,
            items::LeatherArmor::reflect,
            items::LeatherArmor::reflectActivation,
            items::LeatherArmor::poison,
            items::LeatherArmor::poisonActivation,
            items::LeatherArmor::empower,
            items::LeatherArmor::empowerActivation,
        );

    actions_system
        .add_item(
            items::PoisonPotion::id,
            items::PoisonPotion::name,
            items::PoisonPotion::itemType,
            items::PoisonPotion::width,
            items::PoisonPotion::height,
            items::PoisonPotion::price,
            items::PoisonPotion::damage,
            items::PoisonPotion::cleansePoison,
            items::PoisonPotion::chance,
            items::PoisonPotion::cooldown,
            items::PoisonPotion::rarity,
            items::PoisonPotion::armor,
            items::PoisonPotion::armorActivation,
            items::PoisonPotion::regen,
            items::PoisonPotion::regenActivation,
            items::PoisonPotion::reflect,
            items::PoisonPotion::reflectActivation,
            items::PoisonPotion::poison,
            items::PoisonPotion::poisonActivation,
            items::PoisonPotion::empower,
            items::PoisonPotion::empowerActivation,
        );

    actions_system
        .add_item(
            items::AugmentedSword::id,
            items::AugmentedSword::name,
            items::AugmentedSword::itemType,
            items::AugmentedSword::width,
            items::AugmentedSword::height,
            items::AugmentedSword::price,
            items::AugmentedSword::damage,
            items::AugmentedSword::cleansePoison,
            items::AugmentedSword::chance,
            items::AugmentedSword::cooldown,
            items::AugmentedSword::rarity,
            items::AugmentedSword::armor,
            items::AugmentedSword::armorActivation,
            items::AugmentedSword::regen,
            items::AugmentedSword::regenActivation,
            items::AugmentedSword::reflect,
            items::AugmentedSword::reflectActivation,
            items::AugmentedSword::poison,
            items::AugmentedSword::poisonActivation,
            items::AugmentedSword::empower,
            items::AugmentedSword::empowerActivation,
        );

    actions_system
        .add_item(
            items::AugmentedDagger::id,
            items::AugmentedDagger::name,
            items::AugmentedDagger::itemType,
            items::AugmentedDagger::width,
            items::AugmentedDagger::height,
            items::AugmentedDagger::price,
            items::AugmentedDagger::damage,
            items::AugmentedDagger::cleansePoison,
            items::AugmentedDagger::chance,
            items::AugmentedDagger::cooldown,
            items::AugmentedDagger::rarity,
            items::AugmentedDagger::armor,
            items::AugmentedDagger::armorActivation,
            items::AugmentedDagger::regen,
            items::AugmentedDagger::regenActivation,
            items::AugmentedDagger::reflect,
            items::AugmentedDagger::reflectActivation,
            items::AugmentedDagger::poison,
            items::AugmentedDagger::poisonActivation,
            items::AugmentedDagger::empower,
            items::AugmentedDagger::empowerActivation,
        );

    actions_system
        .add_item(
            items::SpikeShield::id,
            items::SpikeShield::name,
            items::SpikeShield::itemType,
            items::SpikeShield::width,
            items::SpikeShield::height,
            items::SpikeShield::price,
            items::SpikeShield::damage,
            items::SpikeShield::cleansePoison,
            items::SpikeShield::chance,
            items::SpikeShield::cooldown,
            items::SpikeShield::rarity,
            items::SpikeShield::armor,
            items::SpikeShield::armorActivation,
            items::SpikeShield::regen,
            items::SpikeShield::regenActivation,
            items::SpikeShield::reflect,
            items::SpikeShield::reflectActivation,
            items::SpikeShield::poison,
            items::SpikeShield::poisonActivation,
            items::SpikeShield::empower,
            items::SpikeShield::empowerActivation,
        );
}

