//! Dice struct and methods for random dice rolls.
/// Source: https://github.com/z-korp/zrisk-contracts/blob/main/src/entities/dice.cairo

// Core imports

use poseidon::PoseidonTrait;
use hash::HashStateTrait;
use traits::Into;

// Constants

const DICE_FACES_NUMBER: u8 = 2;

/// Dice struct.
#[derive(Drop)]
struct Dice {
    seed: felt252,
    nonce: felt252,
}

/// Trait to initialize and roll a dice.
trait DiceTrait {
    /// Returns a new `Dice` struct.
    /// # Arguments
    /// * `seed` - A seed to initialize the dice.
    /// * `wave` - The wave to customize the dice randomness.
    /// # Returns
    /// * The initialized `Dice`.
    fn new(seed: felt252, wave: u8) -> Dice;
    /// Returns a value after a die roll.
    /// # Arguments
    /// * `self` - The Dice.
    /// # Returns
    /// * The value of the dice after a roll.
    fn roll(ref self: Dice) -> u8;
}

/// Implementation of the `DiceTrait` trait for the `Dice` struct.
impl DiceImpl of DiceTrait {
    #[inline(always)]
    fn new(seed: felt252, wave: u8) -> Dice {
        let mut state = PoseidonTrait::new();
        state = state.update(seed);
        state = state.update(wave.into());
        Dice { seed: state.finalize(), nonce: 0 }
    }

    #[inline(always)]
    fn roll(ref self: Dice) -> u8 {
        let mut state = PoseidonTrait::new();
        state = state.update(self.seed);
        state = state.update(self.nonce);
        self.nonce += 1;
        let random: u256 = state.finalize().into();
        (random % DICE_FACES_NUMBER.into()).try_into().unwrap()
    }
}

#[cfg(test)]
mod tests {
    // Core imports

    use debug::PrintTrait;

    // Local imports

    use super::{DiceTrait, DICE_FACES_NUMBER};

    #[test]
    #[available_gas(2000000)]
    fn test_dice_new_roll() {
        let mut dice = DiceTrait::new('seed', 0);
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
        assert(dice.roll() < DICE_FACES_NUMBER, 'Wrong dice value');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_dice_new_roll_overflow() {
        let mut dice = DiceTrait::new('seed', 0);
        dice.nonce = 0x800000000000011000000000000000000000000000000000000000000000000; // PRIME - 1
        dice.roll();
        assert(dice.nonce == 0, 'Wrong dice nonce');
    }
}
