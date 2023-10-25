//! Store struct and component management methods.

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Components imports

use zdefender::models::game::{Game, GameTrait};
use zdefender::models::mob::{Mob, MobTrait};
use zdefender::models::tower::{Tower, TowerTrait};

mod errors {
    const STORE_TOWER_KEY_OUT_OF_BOUNDS: felt252 = 'Store: tower key out of bounds';
}

/// Store struct.
#[derive(Drop)]
struct Store {
    world: IWorldDispatcher
}

/// Trait to initialize, get and set components from the Store.
trait StoreTrait {
    fn new(world: IWorldDispatcher) -> Store;
    fn game(ref self: Store, key: felt252) -> Game;
    fn mob(ref self: Store, game: Game, key: u32) -> Mob;
    fn mobs(ref self: Store, game: Game) -> Array<Mob>;
    fn tower(ref self: Store, game: Game, key: u32) -> Tower;
    fn towers(ref self: Store, game: Game) -> Array<Tower>;
    fn find_tower(ref self: Store, game: Game, index: u32) -> Option<Tower>;
    fn is_tower(ref self: Store, game: Game, index: u32) -> bool;
    fn set_game(ref self: Store, game: Game);
    fn set_mob(ref self: Store, mob: Mob);
    fn set_mobs(ref self: Store, mobs: Array<Mob>);
    fn remove_mob(ref self: Store, game: Game, mob: Mob);
    fn set_tower(ref self: Store, tower: Tower);
    fn set_towers(ref self: Store, ref towers: Array<Tower>);
    fn remove_tower(ref self: Store, game: Game, tower: Tower);
}

/// Implementation of the `StoreTrait` trait for the `Store` struct.
impl StoreImpl of StoreTrait {
    #[inline(always)]
    fn new(world: IWorldDispatcher) -> Store {
        Store { world: world }
    }

    #[inline(always)]
    fn game(ref self: Store, key: felt252) -> Game {
        get!(self.world, key, (Game))
    }

    #[inline(always)]
    fn mob(ref self: Store, game: Game, key: u32) -> Mob {
        let mob_key = (game.id, key);
        get!(self.world, mob_key.into(), (Mob))
    }

    fn mobs(ref self: Store, game: Game) -> Array<Mob> {
        let max: u32 = game.mob_count.into();
        let mut index: u32 = 0;
        let mut mobs: Array<Mob> = array![];
        loop {
            if index == max {
                break;
            };
            let mob = self.mob(game, index);
            if mob.health > 0 {
                mobs.append(mob);
            };
            index += 1;
        };
        mobs
    }

    #[inline(always)]
    fn tower(ref self: Store, game: Game, key: u32) -> Tower {
        // assert(key < game.tower_build.into(), errors::STORE_TOWER_KEY_OUT_OF_BOUNDS);
        let tower_key = (game.id, key);
        get!(self.world, tower_key.into(), (Tower))
    }

    fn towers(ref self: Store, game: Game) -> Array<Tower> {
        let mut index: u32 = game.tower_build.into();
        let mut towers: Array<Tower> = array![];
        loop {
            if index == 0 {
                break;
            };
            index -= 1;
            towers.append(self.tower(game, index));
        };
        towers
    }

    fn find_tower(ref self: Store, game: Game, index: u32) -> Option<Tower> {
        let mut key: u32 = game.tower_build.into();
        loop {
            if key == 0 {
                break Option::None;
            };
            key -= 1;
            let tower = self.tower(game, key);
            if tower.index == index {
                break Option::Some(tower);
            };
        }
    }

    #[inline(always)]
    fn is_tower(ref self: Store, game: Game, index: u32) -> bool {
        match self.find_tower(game, index) {
            Option::Some(_) => true,
            Option::None => false,
        }
    }

    #[inline(always)]
    fn set_game(ref self: Store, game: Game) {
        set!(self.world, (game));
    }

    #[inline(always)]
    fn set_mob(ref self: Store, mob: Mob) {
        set!(self.world, (mob));
    }

    fn set_mobs(ref self: Store, mut mobs: Array<Mob>) {
        loop {
            match mobs.pop_front() {
                Option::Some(mob) => self.set_mob(mob),
                Option::None => {
                    break;
                },
            };
        };
    }

    #[inline(always)]
    fn remove_mob(ref self: Store, game: Game, mob: Mob) {
        let last_mob_key: u32 = game.mob_alive.into() - 1;
        // Skip if the mob key is the latest key
        if last_mob_key == mob.key {
            return;
        }
        // Move last mob to the removed mob position
        let mut last_mob = self.mob(game, last_mob_key);
        last_mob.key = mob.key;
        self.set_mob(last_mob);
    }

    #[inline(always)]
    fn set_tower(ref self: Store, tower: Tower) {
        set!(self.world, (tower));
    }

    fn set_towers(ref self: Store, ref towers: Array<Tower>) {
        loop {
            match towers.pop_front() {
                Option::Some(tower) => self.set_tower(tower),
                Option::None => {
                    break;
                },
            };
        };
    }

    #[inline(always)]
    fn remove_tower(ref self: Store, game: Game, tower: Tower) {
        let mut last_tower_key: u32 = game.tower_build.into() - 1;
        // Replace the tower with the last tower
        if last_tower_key != tower.key {
            let mut last_tower = self.tower(game, last_tower_key);
            last_tower.key = tower.key;
            self.set_tower(last_tower);
        }
        // Remove the last tower
        let mut empty_tower = self.tower(game, game.tower_build.into());
        empty_tower.key = last_tower_key;
        empty_tower.id = tower.id;
        self.set_tower(empty_tower);
    }
}
