#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="https://api.cartridge.gg/x/warpack-masters-v3/katana";

export WORLD_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.world.address')

export ACTIONS_ADDRESS=$(cat ./manifests/deployments/KATANA.json | jq -r '.contracts[] | select(.name == "warpack_masters::systems::actions::actions" ).address')


echo "---------------------------------------------------------------------------"
echo world : $WORLD_ADDRESS
echo " "
echo actions : $ACTIONS_ADDRESS
echo "---------------------------------------------------------------------------"


# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>

# Herb 1214607970,3,1,1,1,0,100,0,1,0,0,1,1,0,0,0,0
# Dagger 75185137345906,1,1,2,2,3,90,4,1,0,0,0,0,0,0,0,0
# Sword 358486078052,1,1,3,2,5,80,5,1,0,0,0,0,0,0,0,0
# Spike 358368242533,3,1,1,2,0,100,0,1,0,0,0,0,1,1,0,0
# Shield 91707909958756,3,2,2,3,0,100,0,1,15,1,0,0,0,0,0,0
# Helmet 79600448005492,3,1,1,3,0,50,0,1,3,2,0,0,0,0,0,0
# Healing Potion 1468365686984687211050012787699566,3,1,1,4,0,100,0,2,0,0,3,1,0,0,0,0
# Leather Armor 6052716152600831465235768242034,3,2,3,5,0,100,0,2,35,1,0,0,0,0,0,0
# Poison Potion 6372733319570045399349322149742,3,1,1,5,0,100,0,2,0,0,0,0,0,0,2,1
# Atlas Band 309101453348888473857636,3,2,1,5,0,100,0,2,25,1,0,0,0,0,0,0
# Augmented Sword 339880532085619196269974512114561636,1,1,3,6,10,80,4,2,0,0,0,0,0,0,0,0
# Augmented Dagger 87009416213918514245113458514029143410,1,1,2,6,6,90,3,2,0,0,0,0,0,0,0,0
# Spike Shield 25823153336537712276388801636,3,2,2,7,0,50,0,2,0,0,0,0,2,2,0,0
# Elder Horns 83927749117907346348207731,3,3,1,8,0,100,0,2,0,0,0,0,4,1,0,0
# Nature Rune 94756431764029820800167525,3,1,1,12,0,75,3,3,0,0,2,3,0,0,0,0
# Plague Flower 6371795136575658587761839400306,3,2,2,12,0,80,4,3,0,0,0,0,0,0,3,3
# Blade Armor 80300916243114438945501042,3,2,3,12,0,100,0,3,75,1,0,0,0,0,0,0

# name, itemType, width, height, price, damage, chance, cooldown, rarity, 
# armor, armorActivation, regen, regenActivation, reflect, reflectActivation, poison, poisonActivation: u8,

sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 1,75185137345906,1,1,2,2,3,90,4,1,0,0,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 2,358486078052,1,1,3,2,5,80,5,1,0,0,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 3,358368242533,3,1,1,2,0,100,0,1,0,0,0,0,1,1,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 4,91707909958756,3,2,2,3,0,100,0,1,15,1,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 5,79600448005492,3,1,1,3,0,50,0,1,3,2,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 6,1468365686984687211050012787699566,3,1,1,4,0,100,0,2,0,0,2,1,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 7,6052716152600831465235768242034,3,2,3,5,0,100,0,2,35,1,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 8,6372733319570045399349322149742,3,1,1,5,0,100,0,2,0,0,0,0,0,0,2,1 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 9,339880532085619196269974512114561636,1,1,3,6,10,80,4,2,0,0,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 10,87009416213918514245113458514029143410,1,1,2,6,6,90,3,2,0,0,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 11,25823153336537712276388801636,3,2,2,7,0,50,0,2,0,0,0,0,2,2,0,0 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 12,6371795136575658587761839400306,3,2,2,12,0,80,4,3,0,0,0,0,0,0,3,3 --wait --rpc-url $RPC_URL 
sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 13,80300916243114438945501042,3,2,3,12,0,100,0,3,75,1,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
# sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 14,1214607970,3,1,1,1,0,100,0,1,0,0,1,1,0,0,0,0 --wait --rpc-url $RPC_URL 
# sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 15,309101453348888473857636,3,2,1,5,0,100,0,2,25,1,0,0,0,0,0,0 --wait --rpc-url $RPC_URL 
# sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 16,83927749117907346348207731,3,3,1,8,0,100,0,2,0,0,0,0,4,1,0,0 --wait --rpc-url $RPC_URL 
# sozo execute --world $WORLD_ADDRESS $ACTIONS_ADDRESS add_item -c 17,94756431764029820800167525,3,1,1,12,0,75,3,3,0,0,2,3,0,0,0,0 --wait --rpc-url $RPC_URL 