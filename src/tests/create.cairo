// Core imports

use debug::PrintTrait;

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Internal imports

use zdefender::constants::GAME_INITIAL_GOLD;
use zdefender::store::{Store, StoreTrait};
use zdefender::models::game::{Game, GameTrait};
use zdefender::models::mob::{Mob, MobTrait, Category as MobCategory};
use zdefender::models::tower::{Tower, TowerTrait, Category as TowerCategory, TOWER_BARBARIAN_COST};
use zdefender::systems::player::IActionsDispatcherTrait;
use zdefender::helpers::map::{Map, MapTrait};
use zdefender::tests::setup::{setup, setup::Systems, setup::PLAYER};

// Constants

const ACCOUNT: felt252 = 'ACCOUNT';
const SEED: felt252 = 'SEED';
const NAME: felt252 = 'NAME';

#[test]
#[available_gas(1_000_000_000)]
fn test_create() {
    // [Setup]
    let (world, systems) = setup::spawn_game();
    let mut store = StoreTrait::new(world);

    // [Create]
    systems.player_actions.create(world, ACCOUNT, SEED, NAME);

    // [Assert] Game
    let game: Game = store.game(ACCOUNT);
    assert(game.id == 0, 'Game: wrong id');
    assert(game.seed == SEED, 'Game: wrong seed');
    assert(game.over == false, 'Game: wrong status');
    assert(game.gold == GAME_INITIAL_GOLD, 'Game: wrong gold');
}
