// Dojo imports

use dojo::world::IWorldDispatcher;

// Internal imports

use zdefender::models::tower::Category as TowerCategory;

// System trait

#[starknet::interface]
trait IActions<TContractState> {
    fn create(
        self: @TContractState,
        world: IWorldDispatcher,
        player: felt252,
        seed: felt252,
        name: felt252,
    );
    fn build(
        self: @TContractState,
        world: IWorldDispatcher,
        player: felt252,
        x: u32,
        y: u32,
        category: TowerCategory,
    );
    fn upgrade(self: @TContractState, world: IWorldDispatcher, player: felt252, x: u32, y: u32,);
    fn sell(self: @TContractState, world: IWorldDispatcher, player: felt252, x: u32, y: u32,);
    fn run(self: @TContractState, world: IWorldDispatcher, player: felt252);
}

// System implementation

#[starknet::contract]
mod actions {
    // Use core lib
    use poseidon::PoseidonTrait;
    use hash::HashStateTrait;

    // Starknet imports

    use starknet::{get_tx_info, get_caller_address};

    // Dojo imports

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Components imports

    use zdefender::models::game::{Game, GameTrait};
    use zdefender::models::mob::{Mob, MobTrait, Category as MobCategory, MOB_ELITE_SPAWN_RATE};
    use zdefender::models::tower::{Tower, TowerTrait, Category as TowerCategory};

    // Helper imports

    use zdefender::helpers::dice::DiceTrait;

    // Internal imports

    use zdefender::store::{Store, StoreTrait};
    use zdefender::helpers::map::{Map, MapTrait};

    // Local imports

    use super::IActions;

    // Errors

    mod errors {
        const BUILD_INVALID_GAME_STATUS: felt252 = 'Build: invalid game status';
        const BUILD_INVALID_POSITION: felt252 = 'Build: invalid position';
        const BUILD_NOT_ENOUGH_GOLD: felt252 = 'Build: not enough gold';
        const UPGRADE_INVALID_GAME_STATUS: felt252 = 'Upgrade: invalid game status';
        const UPGRADE_INVALID_POSITION: felt252 = 'Upgrade: invalid position';
        const UPGRADE_NOT_ENOUGH_GOLD: felt252 = 'Upgrade: not enough gold';
        const SELL_INVALID_GAME_STATUS: felt252 = 'Sell: invalid game status';
        const SELL_INVALID_POSITION: felt252 = 'Sell: invalid position';
        const RUN_INVALID_GAME_STATUS: felt252 = 'Run: invalid game status';
    }

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl Actions of IActions<ContractState> {
        fn create(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            seed: felt252,
            name: felt252,
        ) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game
            let game_id = world.uuid();
            let mut game = GameTrait::new(player, game_id, seed, name);
            store.set_game(game);
        }

        fn build(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            x: u32,
            y: u32,
            category: TowerCategory,
        ) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::BUILD_INVALID_GAME_STATUS);

            // [Check] Enough gold
            let cost = TowerTrait::build_cost(category.into());
            assert(game.gold >= cost, errors::BUILD_NOT_ENOUGH_GOLD);

            // [Check] Tile is idle (no road, no tower)
            let mut map = MapTrait::from(x, y);
            assert(map.is_idle(), errors::BUILD_INVALID_POSITION);
            assert(!store.is_tower(game, map.index), errors::BUILD_INVALID_POSITION);

            // [Effect] Tower
            let tower_id: u32 = game.tower_count.into()
                + 1; // Tower id starts at 1, 0 is reserved for null
            let mut tower = TowerTrait::new(
                game_id: game.id, id: tower_id, index: map.index, category: category
            );
            store.set_tower(tower);

            // [Effect] Game
            game.gold -= cost;
            game.tower_count += 1;
            store.set_game(game);
        }

        fn upgrade(
            self: @ContractState, world: IWorldDispatcher, player: felt252, x: u32, y: u32,
        ) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::UPGRADE_INVALID_GAME_STATUS);

            // [Effect] Tower
            let map = MapTrait::from(x, y);
            let mut tower = store.tower(game, map.index);

            // [Check] Tower exists
            assert(tower.id != 0, errors::UPGRADE_INVALID_POSITION);

            // [Check] Enough gold
            let cost = tower.upgrade_cost();
            assert(game.gold >= cost, errors::UPGRADE_NOT_ENOUGH_GOLD);

            // [Effect] Tower
            let tower_id: u32 = game.tower_count.into()
                + 1; // Tower id starts at 1, 0 is reserved for null
            tower.upgrade();
            store.set_tower(tower);

            // [Effect] Game
            game.gold -= cost;
            store.set_game(game);
        }

        fn sell(self: @ContractState, world: IWorldDispatcher, player: felt252, x: u32, y: u32,) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::SELL_INVALID_GAME_STATUS);

            // [Effect] Tower
            let map = MapTrait::from(x, y);
            let mut tower = store.tower(game, map.index);

            // [Check] Tower exists
            assert(tower.id != 0, errors::SELL_INVALID_POSITION);

            // [Effect] Sell Tower
            let cost = tower.sell_cost();
            store.remove_tower(game, tower);

            // [Effect] Game
            game.tower_count -= 1;
            game.gold += cost;
            store.set_game(game);
        }

        fn run(self: @ContractState, world: IWorldDispatcher, player: felt252) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::RUN_INVALID_GAME_STATUS);

            // [Effect] Tick loop
            let mut dice = DiceTrait::new(game.seed, game.wave);
            let mut tick = 0;
            loop {
                // [Check] Game is over
                if game.health == 0 {
                    game.over = true;
                    break;
                }

                // [Check] Wave is over
                if game.mob_remaining == 0 {
                    game.wave += 1;
                    break;
                }

                // [Effect] Perform mob moves
                let mut index: u32 = game.mob_count.into();
                loop {
                    if index == 0 {
                        break;
                    }
                    index -= 1;
                    let mut mob = store.mob(game, index);
                    let status = mob.move();
                    // [Check] Mob reached castle
                    if status {
                        game.take_damage();
                        store.remove_mob(game, mob);
                    } else {
                        store.set_mob(mob);
                    };
                };

                // [Effect] Perform tower attacks
                let mut index: u32 = game.tower_count.into();
                loop {
                    if index == 0 {
                        break;
                    }

                    let mut tower = store.tower(game, index);
                    index -= 1;
                    if tower.is_frozen(tick) {
                        continue;
                    }

                    let mut mobs = store.mobs(game);
                    loop {
                        match mobs.pop_front() {
                            Option::Some(snap_mob) => {
                                let mut mob = *snap_mob;
                                if !tower.is_frozen(tick) && tower.can_attack(mob) {
                                    tower.attack(ref mob, tick);
                                    if mob.health == 0 {
                                        store.remove_mob(game, mob);
                                    } else {
                                        store.set_mob(mob);
                                    };
                                    store.set_tower(tower);
                                };
                            },
                            Option::None => {
                                break;
                            },
                        };
                    };
                };

                // [Effect] Perform mob spawns
                let mut index = dice.roll(); // Roll a dice to determine how many mob will spawn
                loop {
                    if index == 0 || game.mob_remaining == 0 {
                        break;
                    }
                    let mob_id = game.mob_count.into() + 1;
                    // Category is determined by the remaining mobs
                    let elite_rate = if MOB_ELITE_SPAWN_RATE > game.wave {
                        MOB_ELITE_SPAWN_RATE - game.wave
                    } else {
                        1
                    };
                    let category = if game.mob_remaining == 1 {
                        MobCategory::Boss
                    } else if game.mob_remaining % elite_rate.into() == 0 {
                        MobCategory::Elite
                    } else {
                        MobCategory::Normal
                    };
                    let mut mob = MobTrait::new(game_id: game.id, id: mob_id, category: category);
                    store.set_mob(mob);
                    game.mob_count += 1;
                    game.mob_remaining -= 1;
                    index -= 1;
                };

                // [Effect] Update game
                store.set_game(game);
                tick += 1;
            };

            // [Effect] Update game
            store.set_game(game);
        }
    }
}
