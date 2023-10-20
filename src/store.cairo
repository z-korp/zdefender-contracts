//! Store struct and component management methods.

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Components imports

use zdefender::models::game::{Game, GameTrait};
use zdefender::models::mob::{Mob, MobTrait};
use zdefender::models::tower::{Tower, TowerTrait};

/// Store struct.
#[derive(Drop)]
struct Store {
    world: IWorldDispatcher
}

/// Trait to initialize, get and set components from the Store.
trait StoreTrait {
    fn new(world: IWorldDispatcher) -> Store;
    fn game(ref self: Store, key: felt252) -> Game;
    fn mob(ref self: Store, game: Game, id: u32) -> Mob;
    fn mobs(ref self: Store, game: Game) -> Span<Mob>;
    fn tower(ref self: Store, game: Game, id: u32) -> Tower;
    fn towers(ref self: Store, game: Game) -> Span<Tower>;
    fn is_tower(ref self: Store, game: Game, index: u32) -> bool;
    fn set_game(ref self: Store, game: Game);
    fn set_mob(ref self: Store, mob: Mob);
    fn set_mobs(ref self: Store, mobs: Span<Mob>);
    fn remove_mob(ref self: Store, game: Game, mob: Mob);
    fn set_tower(ref self: Store, tower: Tower);
    fn set_towers(ref self: Store, towers: Span<Tower>);
    fn remove_tower(ref self: Store, game: Game, tower: Tower);
}

/// Implementation of the `StoreTrait` trait for the `Store` struct.
impl StoreImpl of StoreTrait {
    fn new(world: IWorldDispatcher) -> Store {
        Store { world: world }
    }

    fn game(ref self: Store, key: felt252) -> Game {
        get!(self.world, key, (Game))
    }

    fn mob(ref self: Store, game: Game, id: u32) -> Mob {
        let mob_key = (game.id, id);
        get!(self.world, mob_key.into(), (Mob))
    }

    fn mobs(ref self: Store, game: Game) -> Span<Mob> {
        let mut index: u32 = game.mob_count.into();
        let mut mobs: Array<Mob> = array![];
        loop {
            if index == 0 {
                break;
            };
            index -= 1;
            mobs.append(self.mob(game, index));
        };
        mobs.span()
    }

    fn tower(ref self: Store, game: Game, id: u32) -> Tower {
        let tower_key = (game.id, id);
        get!(self.world, tower_key.into(), (Tower))
    }

    fn towers(ref self: Store, game: Game) -> Span<Tower> {
        let mut index: u32 = game.tower_count.into();
        let mut towers: Array<Tower> = array![];
        loop {
            if index == 0 {
                break;
            };
            index -= 1;
            let tower = self.tower(game, index);
            if tower.id != 0 {
                towers.append(tower);
            };
        };
        towers.span()
    }

    fn is_tower(ref self: Store, game: Game, index: u32) -> bool {
        let mut index: u32 = game.tower_count.into();
        loop {
            if index == 0 {
                break false;
            };
            index -= 1;
            let tower = self.tower(game, index);
            if tower.index == index {
                break true;
            };
        }
    }

    fn set_game(ref self: Store, game: Game) {
        set!(self.world, (game));
    }

    fn set_mob(ref self: Store, mob: Mob) {
        set!(self.world, (mob));
    }

    fn set_mobs(ref self: Store, mut mobs: Span<Mob>) {
        loop {
            match mobs.pop_front() {
                Option::Some(mob) => self.set_mob(*mob),
                Option::None => {
                    break;
                },
            };
        };
    }

    fn remove_mob(ref self: Store, game: Game, mob: Mob) {
        let last_mob_id: u32 = game.mob_count.into();
        // Skip if the mob id is the latest id
        if last_mob_id == mob.id {
            return;
        }
        let mut last_mob = self.mob(game, last_mob_id);
        last_mob.id = mob.id;
        self.set_mob(last_mob);
    }

    fn set_tower(ref self: Store, tower: Tower) {
        set!(self.world, (tower));
    }

    fn set_towers(ref self: Store, mut towers: Span<Tower>) {
        loop {
            match towers.pop_front() {
                Option::Some(tower) => self.set_tower(*tower),
                Option::None => {
                    break;
                },
            };
        };
    }

    fn remove_tower(ref self: Store, game: Game, tower: Tower) {
        let last_tower_id: u32 = game.tower_count.into();
        // Skip if the tower id is the latest id
        if last_tower_id == tower.id {
            return;
        }
        let mut last_tower = self.tower(game, last_tower_id);
        last_tower.id = tower.id;
        self.set_tower(last_tower);
    }
}
