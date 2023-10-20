//! Store struct and component management methods.

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Components imports

use zdefender::models::game::{Game, GameTrait};
use zdefender::models::mob::{Mob, MobTrait};
use zdefender::models::tile::{Tile, TileTrait};

// Internal imports

use zdefender::config;

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
    fn tile(ref self: Store, game: Game, index: u32) -> Tile;
    fn tiles(ref self: Store, game: Game) -> Span<Tile>;
    fn set_game(ref self: Store, game: Game);
    fn set_mob(ref self: Store, mob: Mob);
    fn set_mobs(ref self: Store, mobs: Span<Mob>);
    fn set_tile(ref self: Store, tile: Tile);
    fn set_tiles(ref self: Store, tiles: Span<Tile>);
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

    fn tile(ref self: Store, game: Game, index: u32) -> Tile {
        let tile_key = (game.id, index);
        get!(self.world, tile_key.into(), (Tile))
    }

    fn tiles(ref self: Store, game: Game) -> Span<Tile> {
        let mut index = config::TILE_COUNT;
        let mut tiles: Array<Tile> = array![];
        loop {
            if index == 0 {
                break;
            };
            index -= 1;
            tiles.append(self.tile(game, index));
        };
        tiles.span()
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

    fn set_tile(ref self: Store, tile: Tile) {
        set!(self.world, (tile));
    }

    fn set_tiles(ref self: Store, mut tiles: Span<Tile>) {
        loop {
            match tiles.pop_front() {
                Option::Some(tile) => self.set_tile(*tile),
                Option::None => {
                    break;
                },
            };
        };
    }
}
