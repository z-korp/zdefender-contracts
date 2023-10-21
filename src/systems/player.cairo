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
    fn iter(self: @TContractState, world: IWorldDispatcher, player: felt252, tick: u32);
    fn run(self: @TContractState, world: IWorldDispatcher, player: felt252);
}

// System implementation

#[starknet::contract]
mod actions {
    // Core imports

    use debug::PrintTrait;

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
        const UPGRADE_INVALID_TOWER: felt252 = 'Upgrade: invalid tower';
        const UPGRADE_INVALID_POSITION: felt252 = 'Upgrade: invalid position';
        const UPGRADE_NOT_ENOUGH_GOLD: felt252 = 'Upgrade: not enough gold';
        const SELL_INVALID_GAME_STATUS: felt252 = 'Sell: invalid game status';
        const SELL_INVALID_POSITION: felt252 = 'Sell: invalid position';
        const SELL_INVALID_TOWER: felt252 = 'Sell: invalid tower';
        const RUN_INVALID_GAME_STATUS: felt252 = 'Run: invalid game status';
        const RUN_INVALID_MOB_STATUS: felt252 = 'Run: invalid mob status';
        const ITER_INVALID_GAME_STATUS: felt252 = 'Iter: invalid game status';
        const ITER_INVALID_MOB_STATUS: felt252 = 'Iter: invalid mob status';
    }

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Hit: Hit,
    }

    #[derive(Drop, starknet::Event)]
    struct Hit {
        tick: u32,
        from: u32,
        to: u32,
        damage: u32,
    }

    #[external(v0)]
    impl Actions of IActions<ContractState> {
        #[inline(always)]
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

        #[inline(always)]
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
            let tower_id: u32 = game.tower_count.into();
            let mut tower = TowerTrait::new(
                game_id: game.id, key: tower_id, index: map.index, category: category
            );
            store.set_tower(tower);

            // [Effect] Game
            game.gold -= cost;
            game.tower_count += 1;
            store.set_game(game);
        }

        #[inline(always)]
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
            let mut map = MapTrait::from(x, y);
            let mut tower = store.find_tower(game, map.index).expect(errors::UPGRADE_INVALID_TOWER);

            // [Check] Tower exists
            assert(tower.level != 0, errors::UPGRADE_INVALID_POSITION);

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

        #[inline(always)]
        fn sell(self: @ContractState, world: IWorldDispatcher, player: felt252, x: u32, y: u32,) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::SELL_INVALID_GAME_STATUS);

            // [Effect] Tower
            let mut map = MapTrait::from(x, y);
            let mut tower = store.find_tower(game, map.index).expect(errors::SELL_INVALID_TOWER);

            // [Check] Tower exists
            assert(tower.level != 0, errors::SELL_INVALID_POSITION);

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

            // [Check] Game mob remaining
            assert(game.mob_remaining > 0 || game.mob_alive > 0, errors::RUN_INVALID_MOB_STATUS);

            // [Effect] Tick loop
            let wave = game.wave;
            let mut tick = 1;
            loop {
                // [Check] Game or wave is over
                let game: Game = store.game(player);
                if game.health == 0 || game.wave != wave {
                    break;
                }
                self._iter(world, player, tick, ref store);
                tick += 1;
            };

            // [Effect] Update game
            store.set_game(game);
        }

        fn iter(self: @ContractState, world: IWorldDispatcher, player: felt252, tick: u32) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Check] Game is not over
            let game: Game = store.game(player);
            assert(!game.over, errors::ITER_INVALID_GAME_STATUS);

            // [Check] Game mob remaining
            assert(game.mob_remaining > 0 || game.mob_alive > 0, errors::ITER_INVALID_MOB_STATUS);

            // [Effect] Run iteration
            self._iter(world, player, tick, ref store);
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        #[inline(always)]
        fn _iter(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store
        ) {
            // [Effect] Perform mob moves
            let mut game: Game = store.game(player);
            self._move(world, player, tick, ref store, ref game);

            // [Effect] Perform mob spawns
            self._spawn(world, player, tick, ref store, ref game);

            // [Effect] Perform tower attacks
            self._attack(world, player, tick, ref store, ref game);

            // [Effect] Update game
            if game.health == 0 {
                game.over();
            } else if game.mob_alive == 0 && game.mob_remaining == 0 {
                game.next();
            };
            game.tick = tick;
            store.set_game(game);
        }

        #[inline(always)]
        fn _spawn(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game
        ) {
            // [Effect] Perform mob spawns
            let mut dice = DiceTrait::new(game.seed, game.wave, tick);
            let mut index = dice.roll(); // Roll a dice to determine how many mob will spawn
            self.__spawn(world, player, tick, ref store, ref game, index);
        }

        #[inline(always)]
        fn _attack(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game
        ) {
            // [Effect] Perform tower attacks
            let mut towers = store.towers(game);
            self.__attack(world, player, tick, ref store, ref game, ref towers);
        }

        #[inline(always)]
        fn _move(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game
        ) {
            // [Effect] Perform mob moves
            let mut mobs = store.mobs(game);
            self.__move(world, player, tick, ref store, ref game, ref mobs);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn __spawn(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game,
            index: u8
        ) {
            if index == 0 || game.mob_remaining == 0 {
                return;
            }
            let mob_id = game.mob_count.into();
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
            let mut mob = MobTrait::new(
                game_id: game.id, id: mob_id, category: category, tick: tick,
            );
            store.set_mob(mob);
            game.mob_count += 1;
            game.mob_alive += 1;
            game.mob_remaining -= 1;
            self.__spawn(world, player, tick, ref store, ref game, index - 1)
        }

        fn __attack(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game,
            ref towers: Span<Tower>
        ) {
            match towers.pop_front() {
                Option::Some(snap_tower) => {
                    let mut tower = *snap_tower;
                    if !tower.is_idle(tick) {
                        return self.__attack(world, player, tick, ref store, ref game, ref towers);
                    }
                    let mut mobs = store.mobs(game);
                    self
                        .__attack_mob(
                            world, player, tick, ref store, ref game, ref tower, ref mobs
                        );
                    return self.__attack(world, player, tick, ref store, ref game, ref towers);
                },
                Option::None => {
                    return;
                },
            };
        }

        fn __attack_mob(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game,
            ref tower: Tower,
            ref mobs: Span<Mob>
        ) {
            match mobs.pop_front() {
                Option::Some(snap_mob) => {
                    let mut mob = *snap_mob;
                    if tower.can_attack(mob, tick) {
                        let damage = tower.attack(ref mob, tick);
                        if mob.health == 0 {
                            game.gold += mob.reward;
                            store.remove_mob(game, mob);
                            game.mob_alive -= 1;
                        } else {
                            store.set_mob(mob);
                        };
                        store.set_tower(tower);

                        // [Event] Hit
                        let hit = Hit { tick, from: tower.id, to: mob.id, damage, };
                        emit!(world, hit);
                    };
                    return self
                        .__attack_mob(
                            world, player, tick, ref store, ref game, ref tower, ref mobs
                        );
                },
                Option::None => {
                    return;
                },
            };
        }

        fn __move(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            tick: u32,
            ref store: Store,
            ref game: Game,
            ref mobs: Span<Mob>
        ) {
            match mobs.pop_front() {
                Option::Some(snap_mob) => {
                    let mut mob = *snap_mob;
                    let status = mob.move(tick);
                    // [Check] Mob reached castle
                    if status {
                        game.take_damage();
                        store.remove_mob(game, mob);
                        game.mob_alive -= 1;
                    } else {
                        store.set_mob(mob);
                    };
                    return self.__move(world, player, tick, ref store, ref game, ref mobs);
                },
                Option::None => {
                    return;
                },
            };
        }
    }
}
