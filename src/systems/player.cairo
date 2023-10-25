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
    fn upgrade(self: @TContractState, world: IWorldDispatcher, player: felt252, id: u32,);
    fn sell(self: @TContractState, world: IWorldDispatcher, player: felt252, id: u32,);
    fn iter(self: @TContractState, world: IWorldDispatcher, player: felt252, tick: u32);
    fn run(self: @TContractState, world: IWorldDispatcher, player: felt252);
}

// System implementation

#[starknet::contract]
mod actions {
    // Core imports

    use core::array::ArrayTrait;
    use core::array::SpanTrait;
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

    use zdefender::helpers::dice::{Dice, DiceTrait};

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
        game_id: u32,
        tick: u32,
        from_id: u32,
        from_index: u32,
        to_id: u32,
        to_index: u32,
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
            let tower_key: u32 = game.tower_build.into();
            let tower_id: u32 = game.tower_count.into();
            let mut tower = TowerTrait::new(
                game_id: game.id, key: tower_key, id: tower_id, index: map.index, category: category
            );
            store.set_tower(tower);

            // [Effect] Game
            game.gold -= cost;
            game.tower_count += 1;
            game.tower_build += 1;
            store.set_game(game);
        }

        #[inline(always)]
        fn upgrade(self: @ContractState, world: IWorldDispatcher, player: felt252, id: u32,) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::UPGRADE_INVALID_GAME_STATUS);

            // [Effect] Tower
            let mut tower = store.tower(game, id);

            // [Check] Tower exists
            assert(tower.level != 0, errors::UPGRADE_INVALID_POSITION);

            // [Check] Enough gold
            let cost = tower.upgrade_cost();
            assert(game.gold >= cost, errors::UPGRADE_NOT_ENOUGH_GOLD);

            // [Effect] Tower
            tower.upgrade();
            store.set_tower(tower);

            // [Effect] Game
            game.gold -= cost;
            store.set_game(game);
        }

        #[inline(always)]
        fn sell(self: @ContractState, world: IWorldDispatcher, player: felt252, id: u32,) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Effect] Game entity
            let mut game: Game = store.game(player);

            // [Check] Game is not over
            assert(!game.over, errors::SELL_INVALID_GAME_STATUS);

            // [Effect] Tower
            let mut tower = store.tower(game, id);

            // [Check] Tower exists
            assert(tower.level != 0, errors::SELL_INVALID_POSITION);

            // [Effect] Sell Tower
            let cost = tower.sell_cost();
            store.remove_tower(game, tower);

            // [Effect] Game
            game.tower_build -= 1;
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
            let mut dice = DiceTrait::new(game.seed, game.wave, game.tick);
            let mut towers = store.towers(game);
            let wave = game.wave;
            loop {
                game.tick += 1;
                let mut mobs = store.mobs(game);
                self._iter(world, player, ref store, ref game, ref dice, ref towers, ref mobs);

                // [Check] Game or wave is over
                if game.health == 0 || game.wave != wave {
                    break;
                };
            };

            // [Effect] Update towers
            store.set_towers(ref towers);

            // [Effect] Update game
            store.set_game(game);
        }

        fn iter(self: @ContractState, world: IWorldDispatcher, player: felt252, tick: u32) {
            // [Setup] Datastore
            let mut store: Store = StoreTrait::new(world);

            // [Check] Game is not over
            let mut game: Game = store.game(player);
            assert(!game.over, errors::ITER_INVALID_GAME_STATUS);

            // [Check] Game mob remaining
            assert(game.mob_remaining > 0 || game.mob_alive > 0, errors::ITER_INVALID_MOB_STATUS);

            // [Effect] Run iteration
            game.tick += 1;
            let mut dice = DiceTrait::new(game.seed, game.wave, game.tick);
            let mut towers = store.towers(game);
            let mut mobs = store.mobs(game);
            self._iter(world, player, ref store, ref game, ref dice, ref towers, ref mobs);

            // [Effect] Update towers
            store.set_towers(ref towers);

            // [Effect] Update game
            store.set_game(game);
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn _iter(
            self: @ContractState,
            world: IWorldDispatcher,
            player: felt252,
            ref store: Store,
            ref game: Game,
            ref dice: Dice,
            ref towers: Array<Tower>,
            ref mobs: Array<Mob>,
        ) {
            loop {
                match mobs.pop_front() {
                    Option::Some(mob) => {
                        let mut mob = mob;

                        // [Effect] Perform tower attacks
                        let mut tower_index: felt252 = towers.len().into();
                        loop {
                            if 0 == tower_index {
                                break;
                            };
                            tower_index -= 1;

                            let mut tower = towers.pop_front().unwrap();
                            if tower.can_attack(@mob, game.tick) {
                                let damage = tower.attack(ref mob, game.tick);
                                if 0 == mob.health.into() {
                                    game.gold += mob.reward;
                                    game.score += 1;
                                    game.mob_alive -= 1;
                                };

                                // [Event] Hit
                                let hit = Hit {
                                    game_id: game.id,
                                    tick: game.tick,
                                    from_id: tower.id,
                                    from_index: tower.index,
                                    to_id: mob.id,
                                    to_index: mob.index,
                                    damage,
                                };
                                emit!(world, hit);
                            };

                            towers.append(tower);
                        };

                        // [Effect] Perform mob moves
                        let status = mob.move(game.tick);
                        // [Check] Mob reached castle
                        if status {
                            game.take_damage();
                            game.mob_alive -= 1;
                        };
                        store.set_mob(mob);
                    },
                    Option::None => {
                        break;
                    },
                };
            };

            // [Effect] Perform mob spawns
            if 0 != game.mob_remaining.into() * dice.roll().into() {
                let mob = MobTrait::new(
                    game_id: game.id,
                    key: game.mob_count.into(),
                    id: game.mob_count.into(),
                    category: game.spawn(),
                    tick: game.tick,
                    wave: game.wave
                );
                game.mob_count += 1;
                game.mob_alive += 1;
                game.mob_remaining -= 1;
                store.set_mob(mob);
            };

            // [Effect] Update game
            if 0 == game.health.into() {
                game.over();
            } else if 0 == game.mob_alive.into() + game.mob_remaining.into() {
                game.next();
            };
        }
    }
}
