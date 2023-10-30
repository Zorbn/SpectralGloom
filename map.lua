local table_clear = require("table.clear")

Map = {}

Map.TILE_SIZE = 32
Map.WIDTH_TILES = 40
Map.HEIGHT_TILES = 20
Map.WIDTH = Map.WIDTH_TILES * Map.TILE_SIZE
Map.HEIGHT = Map.HEIGHT_TILES * Map.TILE_SIZE

local DECORATION_RANGE = Map.TILE_SIZE * 0.25
local DECORATION_DENSITY = 0.15
local DECORATION_SPRITES = {
    [1] = Atlas.sprites["Weeds1"],
    [2] = Atlas.sprites["Weeds2"],
}

function Map:new()
    local map = {
        decorations = {},
        enemies = {},
        bullets = {},
        particles = {},
        player = Player:new(170, 170),
        enemies_per_tile = {},
        nearby_cache = {},
    }

    setmetatable(map, self)
    self.__index = self

    for _ = 1, Map.WIDTH_TILES * Map.HEIGHT_TILES do
        table.insert(map.enemies_per_tile, {})
    end

    return map
end

function Map:init()
    for y = 1, Map.HEIGHT_TILES do
        for x = 1, Map.WIDTH_TILES do
            if math.random() > DECORATION_DENSITY then
                goto continue
            end

            local decoration_x = x * Map.TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_y = y * Map.TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_type = math.random(1, 2)

            table.insert(self.decorations, {
                x = decoration_x,
                y = decoration_y,
                type = decoration_type,
            })

            -- TODO:
            if math.random() > 0.2 then
                table.insert(self.enemies, Enemy:new(decoration_x, decoration_y))
            end

            ::continue::
        end
    end
end

function Map:update(dt, drawables, camera)
    self.player:update(dt, camera, self.bullets)
    table.insert(drawables, self.player)
    camera:center_on(self.player.x, self.player.y)

    for i = 1, Map.WIDTH_TILES * Map.HEIGHT_TILES do
        table_clear(self.enemies_per_tile[i])
    end
    for _, enemy in pairs(self.enemies) do
        self:add_enemy_to_tile(enemy)
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt, self)

        if enemy.is_dead then
            table.remove(self.enemies, i)
        else
            table.insert(drawables, enemy)
        end
    end

    -- print("Particles:", Particle.allocation_count, "Bullets:", Bullet.allocation_count)

    -- local bullet_update_start = os.clock()
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        bullet:update(dt, self)

        if bullet.is_dead then
            table.remove(self.bullets, i)
            bullet:recycle()
        else
            table.insert(drawables, bullet)
        end
    end
    -- local bullet_update_end = os.clock()
    -- print("Bullet update: " .. (bullet_update_end - bullet_update_start) * 1000 .. "ms", "Enemy count: ", #self.enemies)

    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle:update(dt)

        if particle.is_dead then
            table.remove(self.particles, i)
            particle:recycle()
        else
            table.insert(drawables, particle)
        end
    end
end

function Map:draw(sprite_batch)
    for _, decoration in pairs(self.decorations) do
        sprite_batch:add_sprite(DECORATION_SPRITES[decoration.type], decoration.x, decoration.y, 0)
    end
end

function Map.to_tile_position(x, y)
    return math.ceil(x / Map.TILE_SIZE), math.ceil(y / Map.TILE_SIZE)
end

function Map:add_enemy_to_tile(enemy)
    local tile_x, tile_y = Map.to_tile_position(enemy.x, enemy.y)
    if tile_x < 1 or tile_x > Map.WIDTH_TILES or tile_y < 1 or tile_y > Map.HEIGHT_TILES then
        return
    end

    -- Add this enemy to the tile it is now in after moving.
    local tile_enemies = self.enemies_per_tile[GameMath.index_2d_to_1d(tile_x, tile_y, Map.WIDTH_TILES)]
    table.insert(tile_enemies, enemy)
end

function Map:nearby_enemies(x, y)
    local origin_tile_x, origin_tile_y = Map.to_tile_position(x, y)

    table_clear(self.nearby_cache)

    for adjacent_y = -1, 1 do
        for adjacent_x = -1, 1 do
            local tile_x = origin_tile_x + adjacent_x
            local tile_y = origin_tile_y + adjacent_y

            if tile_x < 1 or tile_x > Map.WIDTH_TILES or tile_y < 1 or tile_y > Map.HEIGHT_TILES then
                goto continue
            end

            local tile_i = GameMath.index_2d_to_1d(tile_x, tile_y, Map.WIDTH_TILES)
            local tile_enemies = self.enemies_per_tile[tile_i]
            for _, enemy in pairs(tile_enemies) do
                table.insert(self.nearby_cache, enemy)
            end

            ::continue::
        end
    end

    return self.nearby_cache
end