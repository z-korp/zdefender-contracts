// Constants

const MAP_SIZE: u32 = 8;
const TILE_SIZE: u32 = 1;
const TILE_COUNT: u32 = 64;
const SPAWN_INDEX: u32 = 48;

mod errors {
    const MAP_INVALID_INDEX: felt252 = 'Map: invalid index';
}

#[derive(Drop)]
struct Map {
    index: u32,
}

trait MapTrait {
    fn new() -> Map;
    fn load(index: u32) -> Map;
    fn from(x: u32, y: u32) -> Map;
    fn x(ref self: Map) -> u32;
    fn y(ref self: Map) -> u32;
    fn box(ref self: Map, range: u32) -> (u32, u32, u32, u32);
    fn next(ref self: Map) -> u32;
    fn is_idle(ref self: Map) -> bool;
}

impl MapImpl of MapTrait {
    #[inline(always)]
    fn new() -> Map {
        Map { index: SPAWN_INDEX, }
    }

    #[inline(always)]
    fn load(index: u32) -> Map {
        Map { index }
    }

    #[inline(always)]
    fn from(x: u32, y: u32) -> Map {
        let index = y * MAP_SIZE + x;
        Map { index }
    }

    #[inline(always)]
    fn x(ref self: Map) -> u32 {
        self.index % MAP_SIZE
    }

    #[inline(always)]
    fn y(ref self: Map) -> u32 {
        self.index / MAP_SIZE
    }

    #[inline(always)]
    fn box(ref self: Map, range: u32) -> (u32, u32, u32, u32) {
        let top = if self.y() < range {
            0
        } else {
            self.y() - range
        };
        let left = if self.x() < range {
            0
        } else {
            self.x() - range
        };
        let bottom = if self.y() + range >= MAP_SIZE {
            MAP_SIZE - 1
        } else {
            self.y() + range
        };
        let right = if self.x() + range >= MAP_SIZE {
            MAP_SIZE - 1
        } else {
            self.x() + range
        };
        (top, left, bottom, right)
    }

    #[inline(always)]
    fn next(ref self: Map) -> u32 {
        if self.index == SPAWN_INDEX {
            return _right(self.index);
        } else if self.index == 49 {
            return _right(self.index);
        } else if self.index == 50 {
            return _up(self.index);
        } else if self.index == 42 {
            return _up(self.index);
        } else if self.index == 34 {
            return _left(self.index);
        } else if self.index == 33 {
            return _up(self.index);
        } else if self.index == 25 {
            return _up(self.index);
        } else if self.index == 17 {
            return _right(self.index);
        } else if self.index == 18 {
            return _up(self.index);
        } else if self.index == 10 {
            return _right(self.index);
        } else if self.index == 11 {
            return _right(self.index);
        } else if self.index == 12 {
            return _right(self.index);
        } else if self.index == 13 {
            return _down(self.index);
        } else if self.index == 21 {
            return _right(self.index);
        } else if self.index == 22 {
            return _down(self.index);
        } else if self.index == 30 {
            return _down(self.index);
        } else if self.index == 38 {
            return _left(self.index);
        } else if self.index == 37 {
            return _down(self.index);
        } else if self.index == 45 {
            return _down(self.index);
        } else if self.index == 53 {
            return _right(self.index);
        } else if self.index == 54 {
            return _right(self.index);
        } else { // Out of the map
            return TILE_COUNT;
        }
    }

    #[inline(always)]
    fn is_idle(ref self: Map) -> bool {
        return self.next() == TILE_COUNT;
    }
}

#[inline(always)]
fn _left(index: u32) -> u32 {
    assert(index > 0, errors::MAP_INVALID_INDEX);
    index - TILE_SIZE
}

#[inline(always)]
fn _right(index: u32) -> u32 {
    assert(index < MAP_SIZE * MAP_SIZE, errors::MAP_INVALID_INDEX);
    index + TILE_SIZE
}

#[inline(always)]
fn _up(index: u32) -> u32 {
    assert(index >= MAP_SIZE, errors::MAP_INVALID_INDEX);
    index - MAP_SIZE
}

#[inline(always)]
fn _down(index: u32) -> u32 {
    assert(index < MAP_SIZE * MAP_SIZE - MAP_SIZE, errors::MAP_INVALID_INDEX);
    index + MAP_SIZE
}

#[cfg(test)]
mod tests {
    // Core imports

    use debug::PrintTrait;

    // Local imports

    use super::{MapTrait, MAP_SIZE, TILE_SIZE, TILE_COUNT, SPAWN_INDEX};

    #[test]
    #[available_gas(2000000)]
    fn test_map_new() {
        let mut map = MapTrait::new();
        assert(map.index == SPAWN_INDEX, 'Map: wrong index');
        assert(map.x() == SPAWN_INDEX % MAP_SIZE, 'Map: wrong x');
        assert(map.y() == SPAWN_INDEX / MAP_SIZE, 'Map: wrong y');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_load() {
        let mut map = MapTrait::load(0);
        assert(map.index == 0, 'Map: wrong index');
        assert(map.x() == 0, 'Map: wrong x');
        assert(map.y() == 0, 'Map: wrong y');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_from() {
        let mut map = MapTrait::from(0, 0);
        assert(map.index == 0, 'Map: wrong index');
        assert(map.x() == 0, 'Map: wrong x');
        assert(map.y() == 0, 'Map: wrong y');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_box_top_left() {
        let mut map = MapTrait::from(0, 0);
        let (top, left, bottom, right) = map.box(1);
        assert(top == 0, 'Map: wrong top');
        assert(left == 0, 'Map: wrong left');
        assert(bottom == 1, 'Map: wrong bottom');
        assert(right == 1, 'Map: wrong right');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_box_top_right() {
        let mut map = MapTrait::from(MAP_SIZE - 1, 0);
        let (top, left, bottom, right) = map.box(1);
        assert(top == 0, 'Map: wrong top');
        assert(left == MAP_SIZE - 2, 'Map: wrong left');
        assert(bottom == 1, 'Map: wrong bottom');
        assert(right == MAP_SIZE - 1, 'Map: wrong right');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_box_bottom_right() {
        let mut map = MapTrait::from(MAP_SIZE - 1, MAP_SIZE - 1);
        let (top, left, bottom, right) = map.box(1);
        assert(top == MAP_SIZE - 2, 'Map: wrong top');
        assert(left == MAP_SIZE - 2, 'Map: wrong left');
        assert(bottom == MAP_SIZE - 1, 'Map: wrong bottom');
        assert(right == MAP_SIZE - 1, 'Map: wrong right');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_box_bottom_left() {
        let mut map = MapTrait::from(0, MAP_SIZE - 1);
        let (top, left, bottom, right) = map.box(1);
        assert(top == MAP_SIZE - 2, 'Map: wrong top');
        assert(left == 0, 'Map: wrong left');
        assert(bottom == MAP_SIZE - 1, 'Map: wrong bottom');
        assert(right == 1, 'Map: wrong right');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_next() {
        let mut map = MapTrait::new();
        assert(map.next() != TILE_COUNT, 'Map: wrong next');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_map_next_not_defined() {
        let mut map = MapTrait::load(0);
        assert(map.next() == TILE_COUNT, 'Map: wrong next');
    }
}
