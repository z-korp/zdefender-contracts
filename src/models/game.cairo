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
    mob_alive: u16,
    wave: u8,
    gold: u16,
    health: u8,
    tick: u32,
    score: u32,
}

trait GameTrait {
    fn new(key: felt252, id: u32, seed: felt252, name: felt252) -> Game;
    fn take_damage(ref self: Game);
    fn over(ref self: Game);
    fn next(ref self: Game);
}

impl GameImpl of GameTrait {
    #[inline(always)]
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
            mob_alive: 0,
            wave: 1,
            gold: constants::GAME_INITIAL_GOLD,
            health: constants::GAME_INITIAL_HEALTH,
            tick: constants::GAME_INITIAL_TICK,
            score: 0,
        }
    }

    #[inline(always)]
    fn take_damage(ref self: Game) {
        self.health -= if self.health > 0 {
            1
        } else {
            0
        };
    }

    #[inline(always)]
    fn over(ref self: Game) {
        self.over = true;
    }

    #[inline(always)]
    fn next(ref self: Game) {
        self.wave += 1;
        self.tick = constants::GAME_INITIAL_TICK;
        // +5% mobs per wave
        self.mob_count = 0;
        self.mob_remaining = constants::GAME_INITIAL_MOB_COUNT
            * (95 + (self.wave * 5)).into()
            / 100;
    }
}

#[cfg(test)]
mod tests {
    // Core imports

    use debug::PrintTrait;

    // Local imports

    use super::{Game, GameTrait};

    // Constants

    const KEY: felt252 = 'KEY';
    const ID: u32 = 0;
    const SEED: felt252 = 'SEED';
    const NAME: felt252 = 'NAME';

    #[test]
    #[available_gas(2000000)]
    fn test_game_new() {
        let mut game = GameTrait::new(KEY, ID, SEED, NAME);
        assert(game.key == KEY, 'Game: wrong key');
        assert(game.id == ID, 'Game: wrong id');
        assert(game.seed == SEED, 'Game: wrong seed');
        assert(game.name == NAME, 'Game: wrong name');
        assert(game.over == false, 'Game: wrong over');
        assert(game.tower_count == 0, 'Game: wrong tower_count');
        assert(game.mob_count == 0, 'Game: wrong mob_count');
        assert(game.mob_remaining > 0, 'Game: wrong mob_remaining');
        assert(game.mob_alive == 0, 'Game: wrong mob_alive');
        assert(game.wave == 1, 'Game: wrong wave');
        assert(game.gold > 0, 'Game: wrong gold');
        assert(game.health > 0, 'Game: wrong health');
        assert(game.tick > 0, 'Game: wrong tick');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_game_take_damage() {
        let mut game = GameTrait::new(KEY, ID, SEED, NAME);
        let health = game.health;
        game.take_damage();
        assert(game.health == health - 1, 'Game: wrong health');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_game_take_damage_no_underflow() {
        let mut game = GameTrait::new(KEY, ID, SEED, NAME);
        game.health = 0;
        game.take_damage();
        assert(game.health == 0, 'Game: wrong health');
    }
}

