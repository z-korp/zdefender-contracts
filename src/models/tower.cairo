//! Tower model;

// Internal imports

use zdefender::helpers::map::{Map, MapTrait};
use zdefender::models::mob::{Mob, MobTrait};

// Constants

const TOWER_BARBARIAN_COOLDOWN: u32 = 1;
const TOWER_BARBARIAN_ATTACK: u32 = 100;
const TOWER_BARBARIAN_RANGE: u32 = 1;
const TOWER_BARBARIAN_COST: u16 = 50;
const TOWER_BOWMAN_COOLDOWN: u32 = 1;
const TOWER_BOWMAN_ATTACK: u32 = 200;
const TOWER_BOWMAN_RANGE: u32 = 2;
const TOWER_BOWMAN_COST: u16 = 50;
const TOWER_WIZARD_COOLDOWN: u32 = 1;
const TOWER_WIZARD_ATTACK: u32 = 100;
const TOWER_WIZARD_RANGE: u32 = 2;
const TOWER_WIZARD_COST: u16 = 50;
const TOWER_SELL_RATIO_NUM: u16 = 75;
const TOWER_SELL_RATIO_DEN: u16 = 100;

#[derive(Model, Copy, Drop, Serde)]
struct Tower {
    #[key]
    game_id: u32,
    #[key]
    id: u32,
    index: u32,
    category: u8,
    cooldown: u32,
    attack: u32,
    range: u32,
    level: u8,
    cost: u16,
    freeze: u32,
}

#[derive(Serde, Copy, Drop, PartialEq)]
enum Category {
    Barbarian,
    Bowman,
    Wizard,
}

impl CategoryIntoU8 of Into<Category, u8> {
    fn into(self: Category) -> u8 {
        match self {
            Category::Barbarian => 0,
            Category::Bowman => 1,
            Category::Wizard => 2,
        }
    }
}

impl U8IntoCategory of Into<u8, Category> {
    fn into(self: u8) -> Category {
        if self == 0 {
            Category::Barbarian
        } else if self == 1 {
            Category::Bowman
        } else {
            Category::Wizard
        }
    }
}

trait TowerTrait {
    fn new(game_id: u32, id: u32, index: u32, category: Category) -> Tower;
    fn is_barbarian(self: Tower) -> bool;
    fn is_bowman(self: Tower) -> bool;
    fn is_wizard(self: Tower) -> bool;
    fn total_cost(self: Tower) -> u16;
    fn sell_cost(self: Tower) -> u16;
    fn upgrade_cost(self: Tower) -> u16;
    fn upgrade(ref self: Tower);
    fn build_cost(category: Category) -> u16;
    fn can_attack(self: Tower, mob: Mob) -> bool;
    fn is_freeze(self: Tower, tick: u32) -> bool;
    fn attack(ref self: Tower, ref mob: Mob, tick: u32);
}

impl TowerImpl of TowerTrait {
    fn new(game_id: u32, id: u32, index: u32, category: Category) -> Tower {
        let (cooldown, attack, range, cost) = match category {
            Category::Barbarian => {
                (
                    TOWER_BARBARIAN_COOLDOWN,
                    TOWER_BARBARIAN_ATTACK,
                    TOWER_BARBARIAN_RANGE,
                    TOWER_BARBARIAN_COST
                )
            },
            Category::Bowman => {
                (TOWER_BOWMAN_COOLDOWN, TOWER_BOWMAN_ATTACK, TOWER_BOWMAN_RANGE, TOWER_BOWMAN_COST)
            },
            Category::Wizard => {
                (TOWER_WIZARD_COOLDOWN, TOWER_WIZARD_ATTACK, TOWER_WIZARD_RANGE, TOWER_WIZARD_COST)
            },
        };
        Tower {
            game_id,
            id,
            index,
            category: category.into(),
            cooldown,
            attack,
            range,
            level: 1,
            cost,
            freeze: 0,
        }
    }

    fn is_barbarian(self: Tower) -> bool {
        self.category == Category::Barbarian.into()
    }

    fn is_bowman(self: Tower) -> bool {
        self.category == Category::Bowman.into()
    }

    fn is_wizard(self: Tower) -> bool {
        self.category == Category::Wizard.into()
    }

    fn total_cost(self: Tower) -> u16 {
        let cost = TowerTrait::build_cost(self.category.into());
        cost * self.level.into()
    }

    fn sell_cost(self: Tower) -> u16 {
        TOWER_SELL_RATIO_NUM * self.cost / TOWER_SELL_RATIO_DEN
    }

    fn upgrade_cost(self: Tower) -> u16 {
        let cost = TowerTrait::build_cost(self.category.into());
        cost * (self.level + 1).into()
    }

    fn upgrade(ref self: Tower) {
        self.cost += self.upgrade_cost();
        self.attack *= 2;
        self.level += 1;
    }

    fn build_cost(category: Category) -> u16 {
        match category {
            Category::Barbarian => TOWER_BARBARIAN_COST,
            Category::Bowman => TOWER_BOWMAN_COST,
            Category::Wizard => TOWER_WIZARD_COST,
        }
    }

    fn can_attack(self: Tower, mob: Mob) -> bool {
        let mut map = MapTrait::load(self.index);
        let (top, left, bottom, right) = map.box(self.range);
        let mut map = MapTrait::load(mob.index);
        let mob_x = map.x();
        let mob_y = map.y();
        mob_x >= left && mob_x <= right && mob_y >= top && mob_y <= bottom
    }

    fn is_freeze(self: Tower, tick: u32) -> bool {
        tick >= self.freeze
    }

    fn attack(ref self: Tower, ref mob: Mob, tick: u32) {
        let damage = if self.attack > mob.defense {
            self.attack - mob.defense
        } else {
            0
        };
        mob.health -= if damage > mob.health {
            mob.health
        } else {
            damage
        };
        self.freeze = tick + self.cooldown;
    }
}
