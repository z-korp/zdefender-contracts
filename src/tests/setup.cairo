mod setup {
    // Starknet imports

    use starknet::ContractAddress;
    use starknet::testing::set_contract_address;

    // Dojo imports

    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // Internal imports

    use zdefender::models::game::{game, Game};
    use zdefender::models::mob::{mob, Mob};
    use zdefender::models::tower::{tower, Tower};
    use zdefender::systems::player::{actions as player_actions, IActionsDispatcher};

    // Constants

    fn PLAYER() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER'>()
    }

    #[derive(Drop)]
    struct Systems {
        player_actions: IActionsDispatcher,
    }

    fn spawn_game() -> (IWorldDispatcher, Systems) {
        // [Setup] World
        let mut models = array::ArrayTrait::new();
        models.append(game::TEST_CLASS_HASH);
        models.append(mob::TEST_CLASS_HASH);
        models.append(tower::TEST_CLASS_HASH);
        let world = spawn_test_world(models);

        // [Setup] Systems
        let player_actions_address = deploy_contract(
            player_actions::TEST_CLASS_HASH, array![].span()
        );
        let systems = Systems {
            player_actions: IActionsDispatcher { contract_address: player_actions_address },
        };

        // [Return]
        set_contract_address(PLAYER());
        (world, systems)
    }
}
