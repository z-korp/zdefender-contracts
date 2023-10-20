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
