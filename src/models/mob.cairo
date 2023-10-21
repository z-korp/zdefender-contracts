//! Mob model

// Internal imports

use zdefender::helpers::map::{Map, MapTrait, SPAWN_INDEX};
use zdefender::models::game::{Game, GameTrait};

// Constants

const MOB_NORMAL_HEALTH: u32 = 100;
const MOB_NORMAL_SPEED: u32 = 1;
const MOB_NORMAL_DEFENSE: u32 = 1;
const MOB_NORMAL_REWARD: u16 = 1;
const MOB_ELITE_HEALTH: u32 = 200;
const MOB_ELITE_SPEED: u32 = 1;
const MOB_ELITE_DEFENSE: u32 = 5;
const MOB_ELITE_REWARD: u16 = 5;
const MOB_BOSS_HEALTH: u32 = 300;
const MOB_BOSS_SPEED: u32 = 1;
const MOB_BOSS_DEFENSE: u32 = 10;
const MOB_BOSS_REWARD: u16 = 50;
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
    key: u32,
    id: u32,
    index: u32,
    previous_index: u32,
    next_index: u32,
    health: u32,
    speed: u32,
    defense: u32,
    reward: u16,
    tick: u32,
}

trait MobTrait {
    fn new(game_id: u32, key: u32, id: u32, category: Category, tick: u32) -> Mob;
    fn move(ref self: Mob, tick: u32) -> bool;
}

impl MobImpl of MobTrait {
    #[inline(always)]
    fn new(game_id: u32, key: u32, id: u32, category: Category, tick: u32) -> Mob {
        let (health, speed, defense, reward) = match category {
            Category::Normal => {
                (MOB_NORMAL_HEALTH, MOB_NORMAL_SPEED, MOB_NORMAL_DEFENSE, MOB_NORMAL_REWARD)
            },
            Category::Elite => {
                (MOB_ELITE_HEALTH, MOB_ELITE_SPEED, MOB_ELITE_DEFENSE, MOB_ELITE_REWARD)
            },
            Category::Boss => {
                (MOB_BOSS_HEALTH, MOB_BOSS_SPEED, MOB_BOSS_DEFENSE, MOB_BOSS_REWARD)
            },
        };
        let index = SPAWN_INDEX;
        let mut map = MapTrait::load(index);
        let next_index = map.next();
        Mob {
            game_id,
            key,
            id,
            index,
            previous_index: index,
            next_index,
            health,
            speed,
            defense,
            reward,
            tick
        }
    }

    fn move(ref self: Mob, tick: u32) -> bool {
        let mut index = self.speed;
        loop {
            // [Break] If all moves done
            if index == 0 {
                break false;
            }
            // [Break] Mob is reaching the player castle
            let mut map = MapTrait::load(self.index);
            if map.is_idle() {
                break true;
            }
            self.previous_index = self.index;
            self.index = map.next();
            map = MapTrait::load(self.index);
            self.next_index = map.next();
            self.tick = tick;
            index -= 1;
        }
    }
}

#[cfg(test)]
mod tests {
    // Core imports

    use debug::PrintTrait;

    // Local imports

    use super::{Mob, MobTrait, Category};

    // Constants

    const GAME_ID: u32 = 0;
    const KEY: u32 = 0;
    const ID: u32 = 0;
    const TICK: u32 = 0;

    #[test]
    #[available_gas(2000000)]
    fn test_mob_new() {
        let mut mob = MobTrait::new(GAME_ID, KEY, ID, Category::Normal, TICK);
        assert(mob.game_id == GAME_ID, 'Mob: wrong game id');
        assert(mob.key == KEY, 'Mob: wrong id');
        assert(mob.id == KEY, 'Mob: wrong id');
        assert(mob.index == super::SPAWN_INDEX, 'Mob: wrong index');
        assert(mob.previous_index == super::SPAWN_INDEX, 'Mob: wrong previous index');
        assert(mob.next_index != super::SPAWN_INDEX, 'Mob: wrong next index');
        assert(mob.health == super::MOB_NORMAL_HEALTH, 'Mob: wrong health');
        assert(mob.speed == super::MOB_NORMAL_SPEED, 'Mob: wrong speed');
        assert(mob.defense == super::MOB_NORMAL_DEFENSE, 'Mob: wrong defense');
        assert(mob.reward == super::MOB_NORMAL_REWARD, 'Mob: wrong reward');
        assert(mob.tick == 0, 'Mob: wrong tick');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_mob_move() {
        let mut mob = MobTrait::new(GAME_ID, KEY, ID, Category::Normal, TICK);
        let index = mob.index;
        let tick = 1;
        let status = mob.move(tick);
        assert(!status, 'Mob: wrong move status');
        assert(mob.tick == tick, 'Mob: wrong tick');
    }
}
