#[derive(Model, Copy, Drop, Serde)]
struct Tile {
    #[key]
    game_id: u32,
    #[key]
    index: u32,
    category: u8,
}

#[derive(Serde, Copy, Drop, PartialEq)]
enum Category {
    Idle,
    Road,
    Tower,
}

impl TurnIntoU8 of Into<Category, u8> {
    fn into(self: Category) -> u8 {
        match self {
            Category::Idle => 0,
            Category::Road => 1,
            Category::Tower => 2,
        }
    }
}

trait TileTrait {
    fn new(game_id: u32, index: u32) -> Tile;
    fn is_idle(self: Tile) -> bool;
    fn is_road(self: Tile) -> bool;
    fn is_tower(self: Tile) -> bool;
    fn set_category(ref self: Tile, category: Category);
}

impl TileImpl of TileTrait {
    fn new(game_id: u32, index: u32) -> Tile {
        Tile { game_id, index, category: Category::Idle.into(), }
    }

    fn is_idle(self: Tile) -> bool {
        self.category == Category::Idle.into()
    }

    fn is_road(self: Tile) -> bool {
        self.category == Category::Road.into()
    }

    fn is_tower(self: Tile) -> bool {
        self.category == Category::Tower.into()
    }

    fn set_category(ref self: Tile, category: Category) {
        self.category = category.into();
    }
}
