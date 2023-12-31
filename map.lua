local table_clear = require("table.clear")

Map = {
    STATE_IN_GAME = 0,
    STATE_GAME_OVER = 1,
    STATE_WIN = 2,
}

Map.TILE_SIZE = 32
Map.BORDER_SIZE = Map.TILE_SIZE * 0.5
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
local BG_R, BG_G, BG_B = 52 / 255, 28 / 255, 39 / 255
local BORDER_SPRITE = Atlas.sprites["BorderShadow"]
local MAX_GRAVESTONE_COUNT = 6

function Map:new()
    local map = {
        enemies = {},
        bullets = {},
        particles = {},
        decorations = {},
        gravestones = {},
        gravestones_destroyed = {},
        nearby_cache = {},
        enemies_per_tile = {},
        player = Player:new(170, 170),
        max_enemies_per_gravestone = 1,
        state = Map.STATE_IN_GAME,
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

            ::continue::
        end
    end

    for _ = 1, MAX_GRAVESTONE_COUNT do
        local x = math.random(0, Map.WIDTH)
        local y = math.random(0, Map.HEIGHT)
        table.insert(self.gravestones, Gravestone:new(x, y))
    end

    -- Right after initializing the map is a good time to collect garbage
    -- to clean up any previous maps.
    collectgarbage("collect")
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

    for i = #self.gravestones, 1, -1 do
        local gravestone = self.gravestones[i]

        gravestone:update(self)

        if gravestone.is_dead then
            table.remove(self.gravestones, i)
            table.insert(self.gravestones_destroyed, GravestoneDestroyed:new(gravestone.x, gravestone.y))
            self.max_enemies_per_gravestone = self.max_enemies_per_gravestone * 2
        else
            table.insert(drawables, gravestone)
        end
    end

    for _, gravestone_destroyed in pairs(self.gravestones_destroyed) do
        table.insert(drawables, gravestone_destroyed)
    end

    if self.state == Map.STATE_IN_GAME then
        if self.player.is_dead then
            self.state = Map.STATE_GAME_OVER
        elseif #self.enemies == 0 and #self.gravestones == 0 then
            self.state = Map.STATE_WIN
        end
    end
end

function Map:draw(sprite_batch)
    love.graphics.setColor(BG_R, BG_G, BG_B, 1)
    love.graphics.rectangle("fill", -Map.BORDER_SIZE, -Map.BORDER_SIZE, Map.WIDTH + Map.BORDER_SIZE * 2,
        Map.HEIGHT + Map.BORDER_SIZE * 2)
    love.graphics.setColor(1, 1, 1, 1)

    -- Allow the draw function to be called once and cached into a sprite batch, then
    -- called each frame to only draw the non-sprites.
    if not sprite_batch then
        return
    end

    for _, decoration in pairs(self.decorations) do
        sprite_batch:add_sprite(DECORATION_SPRITES[decoration.type], decoration.x, decoration.y, 0)
    end

    for x = 0, Map.WIDTH_TILES do
        sprite_batch:add_sprite(BORDER_SPRITE, x * Map.TILE_SIZE, -Map.BORDER_SIZE, 0, 0)
    end

    for x = 0, Map.WIDTH_TILES do
        sprite_batch:add_sprite(BORDER_SPRITE, x * Map.TILE_SIZE, Map.HEIGHT + Map.BORDER_SIZE, 0, math.pi)
    end

    for y = 0, Map.WIDTH_TILES do
        sprite_batch:add_sprite(BORDER_SPRITE, -Map.BORDER_SIZE, y * Map.TILE_SIZE, 0, math.pi * 1.5)
    end

    for y = 0, Map.WIDTH_TILES do
        sprite_batch:add_sprite(BORDER_SPRITE, Map.WIDTH + Map.BORDER_SIZE, y * Map.TILE_SIZE, 0, math.pi * 0.5)
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