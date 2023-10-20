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
}

// System implementation

#[starknet::contract]
mod actions {
    // Starknet imports

    use starknet::{get_tx_info, get_caller_address};

    // Dojo imports

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // Components imports

    use zdefender::models::game::{Game, GameTrait};
    use zdefender::models::mob::{Mob, MobTrait};
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
            let cost = TowerTrait::cost(category.into());
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
    }
}
