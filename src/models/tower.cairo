//! Tower model;

// Constants

const TOWER_BARBARIAN_SPEED: u32 = 1;
const TOWER_BARBARIAN_ATTACK: u32 = 1;
const TOWER_BARBARIAN_RANGE: u32 = 1;
const TOWER_BARBARIAN_COST: u16 = 50;
const TOWER_BOWMAN_SPEED: u32 = 1;
const TOWER_BOWMAN_ATTACK: u32 = 2;
const TOWER_BOWMAN_RANGE: u32 = 2;
const TOWER_BOWMAN_COST: u16 = 50;
const TOWER_WIZARD_SPEED: u32 = 1;
const TOWER_WIZARD_ATTACK: u32 = 1;
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
    speed: u32,
    attack: u32,
    range: u32,
    level: u8,
    cost: u16
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
}

impl TowerImpl of TowerTrait {
    fn new(game_id: u32, id: u32, index: u32, category: Category) -> Tower {
        let (speed, attack, range, cost) = match category {
            Category::Barbarian => {
                (
                    TOWER_BARBARIAN_SPEED,
                    TOWER_BARBARIAN_ATTACK,
                    TOWER_BARBARIAN_RANGE,
                    TOWER_BARBARIAN_COST
                )
            },
            Category::Bowman => {
                (TOWER_BOWMAN_SPEED, TOWER_BOWMAN_ATTACK, TOWER_BOWMAN_RANGE, TOWER_BOWMAN_COST)
            },
            Category::Wizard => {
                (TOWER_WIZARD_SPEED, TOWER_WIZARD_ATTACK, TOWER_WIZARD_RANGE, TOWER_WIZARD_COST)
            },
        };
        Tower {
            game_id, id, index, category: category.into(), speed, attack, range, level: 1, cost
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
        self.speed *= 2;
        self.level += 1;
    }

    fn build_cost(category: Category) -> u16 {
        match category {
            Category::Barbarian => TOWER_BARBARIAN_COST,
            Category::Bowman => TOWER_BOWMAN_COST,
            Category::Wizard => TOWER_WIZARD_COST,
        }
    }
}
