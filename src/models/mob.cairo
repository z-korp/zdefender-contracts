//! Mob model

// Internal imports

use zdefender::config;

// Constants

const MOB_NORMAL_HEALTH: u32 = 100;
const MOB_NORMAL_SPEED: u32 = 100;
const MOB_NORMAL_DEFENCE: u32 = 100;
const MOB_ELITE_HEALTH: u32 = 1000;
const MOB_ELITE_SPEED: u32 = 100;
const MOB_ELITE_DEFENCE: u32 = 200;
const MOB_BOSS_HEALTH: u32 = 10000;
const MOB_BOSS_SPEED: u32 = 50;
const MOB_BOSS_DEFENCE: u32 = 500;

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
    defence: u32,
}

trait MobTrait {
    fn new(game_id: u32, id: u32, category: Category) -> Mob;
}

impl MobImpl of MobTrait {
    fn new(game_id: u32, id: u32, category: Category) -> Mob {
        let (health, speed, defence) = match category {
            Category::Normal => {
                (MOB_NORMAL_HEALTH, MOB_NORMAL_SPEED, MOB_NORMAL_DEFENCE)
            },
            Category::Elite => {
                (MOB_ELITE_HEALTH, MOB_ELITE_SPEED, MOB_ELITE_DEFENCE)
            },
            Category::Boss => {
                (MOB_BOSS_HEALTH, MOB_BOSS_SPEED, MOB_BOSS_DEFENCE)
            },
        };
        Mob { game_id, id, index: config::SPAWN_INDEX, health, speed, defence, }
    }
}
