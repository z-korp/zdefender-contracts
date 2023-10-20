//! Mob model

// Internal imports

use zdefender::helpers::map::{Map, MapTrait, SPAWN_INDEX};
use zdefender::models::game::{Game, GameTrait};

// Constants

const MOB_NORMAL_HEALTH: u32 = 100;
const MOB_NORMAL_SPEED: u32 = 2;
const MOB_NORMAL_DEFENSE: u32 = 10;
const MOB_ELITE_HEALTH: u32 = 1000;
const MOB_ELITE_SPEED: u32 = 1;
const MOB_ELITE_DEFENSE: u32 = 100;
const MOB_BOSS_HEALTH: u32 = 10000;
const MOB_BOSS_SPEED: u32 = 1;
const MOB_BOSS_DEFENSE: u32 = 1000;
const MOB_ELITE_SPAWN_RATE: u8 = 13;

#[derive(Drop, PartialEq)]
enum Category {
    Normal,
    Elite,
    Boss,
}

#[derive(Model, Copy, Drop, Serde)]
struct Mob {
    #[key]
    game_id: u32,
    #[key]
    id: u32,
    index: u32,
    health: u32,
    speed: u32,
    defense: u32,
}

trait MobTrait {
    fn new(game_id: u32, id: u32, category: Category) -> Mob;
    fn move(ref self: Mob, ref game: Game);
}

impl MobImpl of MobTrait {
    fn new(game_id: u32, id: u32, category: Category) -> Mob {
        let (health, speed, defense) = match category {
            Category::Normal => {
                (MOB_NORMAL_HEALTH, MOB_NORMAL_SPEED, MOB_NORMAL_DEFENSE)
            },
            Category::Elite => {
                (MOB_ELITE_HEALTH, MOB_ELITE_SPEED, MOB_ELITE_DEFENSE)
            },
            Category::Boss => {
                (MOB_BOSS_HEALTH, MOB_BOSS_SPEED, MOB_BOSS_DEFENSE)
            },
        };
        Mob { game_id, id, index: SPAWN_INDEX, health, speed, defense, }
    }

    fn move(ref self: Mob, ref game: Game) {
        let mut index = self.speed;
        loop {
            let mut map = MapTrait::load(self.index);
            // [Break] If all moves done
            if index == 0 {
                break;
            }
            // [Break] Mob is reaching the player nexus
            if map.is_idle() {
                game.take_damage();
                break;
            }
            self.index = map.next();
            index -= 1;
        };
    }
}
