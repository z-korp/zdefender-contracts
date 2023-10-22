// Core imports

use debug::PrintTrait;

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports

use zdefender::constants::GAME_INITIAL_GOLD;
use zdefender::store::{Store, StoreTrait};
use zdefender::models::game::{Game, GameTrait};
use zdefender::models::mob::{Mob, MobTrait, Category as MobCategory};
use zdefender::models::tower::{
    Tower, TowerTrait, Category as TowerCategory, TOWER_BARBARIAN_COST, TOWER_SELL_RATIO_NUM,
    TOWER_SELL_RATIO_DEN
};
use zdefender::systems::player::IActionsDispatcherTrait;
use zdefender::helpers::map::{Map, MapTrait};
use zdefender::tests::setup::{setup, setup::Systems, setup::PLAYER};

// Constants

const ACCOUNT: felt252 = 'ACCOUNT';
const SEED: felt252 = 'SEED';
const NAME: felt252 = 'NAME';

#[test]
#[available_gas(1_000_000_000)]
fn test_sell() {
    // [Setup]
    let (world, systems) = setup::spawn_game();
    let mut store = StoreTrait::new(world);

    // [Create]
    systems.player_actions.create(world, ACCOUNT, SEED, NAME);

    // [Build]
    let mut map = MapTrait::from(2, 3);
    systems.player_actions.build(world, ACCOUNT, map.x(), map.y(), TowerCategory::Barbarian);

    // [Upgrade]
    let tower_key = 0;
    systems.player_actions.upgrade(world, ACCOUNT, tower_key);

    // [Sell]
    systems.player_actions.sell(world, ACCOUNT, tower_key);

    // [Assert] Game
    let game: Game = store.game(ACCOUNT);
    let gold = TOWER_SELL_RATIO_NUM * 2 * TOWER_BARBARIAN_COST / TOWER_SELL_RATIO_DEN;
    assert(game.gold == gold, 'Game: wrong gold');
    assert(game.tower_count == 1, 'Game: wrong tower count');
    assert(game.tower_build == 0, 'Game: wrong tower build');
}

#[test]
#[available_gas(1_000_000_000)]
fn test_sell_rebuild() {
    // [Setup]
    let (world, systems) = setup::spawn_game();
    let mut store = StoreTrait::new(world);

    // [Create]
    systems.player_actions.create(world, ACCOUNT, SEED, NAME);

    // [Build]
    let mut map = MapTrait::from(2, 3);
    systems.player_actions.build(world, ACCOUNT, map.x(), map.y(), TowerCategory::Barbarian);

    // [Upgrade]
    let tower_key = 0;
    systems.player_actions.upgrade(world, ACCOUNT, tower_key);

    // [Sell]
    systems.player_actions.sell(world, ACCOUNT, tower_key);

    // [Build]
    systems.player_actions.build(world, ACCOUNT, map.x(), map.y(), TowerCategory::Bowman);

    // [Assert] Game
    let game: Game = store.game(ACCOUNT);
    assert(game.tower_count == 2, 'Game: wrong tower count');
    assert(game.tower_build == 1, 'Game: wrong tower build');

    // [Assert] Tower
    let tower: Tower = store.tower(game, tower_key);
    assert(tower.key == 0, 'Game: wrong tower count');
    assert(tower.id == 1, 'Game: wrong tower build');
}
