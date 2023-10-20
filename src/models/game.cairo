//! Game model

// Internal imports

use zdefender::constants;

#[derive(Model, Copy, Drop, Serde)]
struct Game {
    #[key]
    key: felt252,
    id: u32,
    name: felt252,
    seed: felt252,
    over: bool,
    tower_count: u8,
    mob_count: u16,
    mob_remaining: u16,
    wave: u8,
    gold: u16,
}

trait GameTrait {
    fn new(key: felt252, id: u32, seed: felt252, name: felt252) -> Game;
}

impl GameImpl of GameTrait {
    fn new(key: felt252, id: u32, seed: felt252, name: felt252) -> Game {
        Game {
            key: key,
            id: id,
            name: name,
            seed: seed,
            over: false,
            tower_count: 0,
            mob_count: 0,
            mob_remaining: constants::GAME_INITIAL_MOB_COUNT,
            wave: 0,
            gold: constants::GAME_INITIAL_GOLD,
        }
    }
}
