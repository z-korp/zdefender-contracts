// Dojo imports

use dojo::world::IWorldDispatcher;

// System trait

#[starknet::interface]
trait IActions<TContractState> {
    fn create(
        self: @TContractState,
        world: IWorldDispatcher,
        account: felt252,
        seed: felt252,
        name: felt252,
    );
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
    use zdefender::models::tile::{Tile, TileTrait};

    // Helper imports

    use zdefender::helpers::dice::DiceTrait;

    // Internal imports

    use zdefender::store::{Store, StoreTrait};
    use zdefender::config;

    // Local imports

    use super::IActions;

    // Errors

    mod errors {}

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl Actions of IActions<ContractState> {
        fn create(
            self: @ContractState,
            world: IWorldDispatcher,
            account: felt252,
            seed: felt252,
            name: felt252,
        ) {
            // [Setup] Datastore
            let mut datastore: Store = StoreTrait::new(world);

            // [Effect] Game
            let game_id = world.uuid();
            let mut game = GameTrait::new(account, game_id, seed, name);
            datastore.set_game(game);
        }
    }
}
