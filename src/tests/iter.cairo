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
use zdefender::systems::player::{IActionsDispatcherTrait, actions::Hit};
use zdefender::helpers::map::{Map, MapTrait};
use zdefender::tests::setup::{setup, setup::Systems, setup::PLAYER};

// Constants

const ACCOUNT: felt252 = 'ACCOUNT';
const SEED: felt252 = 'SEED';
const NAME: felt252 = 'NAME';

#[test]
#[available_gas(1_000_000_000_000)]
fn test_iter() {
    // [Setup]
    let (world, systems) = setup::spawn_game();
    let mut store = StoreTrait::new(world);

    // [Create]
    systems.player_actions.create(world, ACCOUNT, SEED, NAME);

    // [Build]
    let mut map = MapTrait::from(1, 5);
    systems.player_actions.build(world, ACCOUNT, map.x(), map.y(), TowerCategory::Barbarian);

    // [Upgrade] 
    systems.player_actions.upgrade(world, ACCOUNT, map.x(), map.y());

    // [Run]
    let mut tick = 1;
    systems.player_actions.iter(world, ACCOUNT, tick);

    // [Assert] Game
    let game: Game = store.game(ACCOUNT);
    assert(game.over == false, 'Game: wrong status');
}

#[test]
#[available_gas(1_000_000_000_000)]
fn test_iter_multi() {
    // [Setup]
    let (world, systems) = setup::spawn_game();
    let mut store = StoreTrait::new(world);

    // [Create]
    systems.player_actions.create(world, ACCOUNT, SEED, NAME);

    // [Build]
    let mut map = MapTrait::from(1, 5);
    systems.player_actions.build(world, ACCOUNT, map.x(), map.y(), TowerCategory::Barbarian);

    // [Upgrade] 
    systems.player_actions.upgrade(world, ACCOUNT, map.x(), map.y());

    // [Run]
    let mut tick = 1;
    loop {
        let game: Game = store.game(ACCOUNT);
        if game.wave > 1 || tick > 100 {
            break;
        }
        systems.player_actions.iter(world, ACCOUNT, tick);
        tick += 1;
    };

    // [Assert] Game
    tick.print();
}
