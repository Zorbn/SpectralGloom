local GRAVESTONE_SPRITE = Atlas.sprites["Gravestone"]
local GRAVESTONE_SHADOW_SHAPE_SPRITE = Atlas.sprites["GravestoneShadowShape"]
local SQUARE_SPRITE = Atlas.sprites["Square"]

local MAX_HEALTH = 1000
local HEALTH_BAR_HEIGHT = 4

local HEALTH_BAR_BG_R = 16 / 255
local HEALTH_BAR_BG_G = 20 / 255
local HEALTH_BAR_BG_B = 31 / 255

local HEALTH_BAR_FG_R = 117 / 255
local HEALTH_BAR_FG_G = 167 / 255
local HEALTH_BAR_FG_B = 67 / 255

Gravestone = {
    RADIUS = 16,
}

function Gravestone:new(x, y)
    local gravestone = {
        x = x,
        y = y,
        spawned_enemies = {},
        health = MAX_HEALTH,
        is_dead = false,
    }

    setmetatable(gravestone, self)
    self.__index = self

    return gravestone
end

function Gravestone:draw(sprite_batch, shadow_sprite_batch)
    sprite_batch:add_sprite(GRAVESTONE_SPRITE, self.x, self.y, 0, 0)
    shadow_sprite_batch:add_shadow(GRAVESTONE_SHADOW_SHAPE_SPRITE, self.x, self.y, 0, 0)

    local health_bar_x = self.x - GRAVESTONE_SPRITE.width * 0.5
    local health_bar_y = self.y + GRAVESTONE_SPRITE.height * 0.5
    local health_bar_filled_percentage = self.health / MAX_HEALTH

    sprite_batch:set_color(HEALTH_BAR_BG_R, HEALTH_BAR_BG_G, HEALTH_BAR_BG_B, 1)
    sprite_batch:add_sprite(SQUARE_SPRITE, health_bar_x, health_bar_y, 0, 0,
        GRAVESTONE_SPRITE.width, HEALTH_BAR_HEIGHT, 0, 0)
    sprite_batch:set_color(HEALTH_BAR_FG_R, HEALTH_BAR_FG_G, HEALTH_BAR_FG_B, 1)
    sprite_batch:add_sprite(SQUARE_SPRITE, health_bar_x, health_bar_y, 0, 0,
        GRAVESTONE_SPRITE.width * health_bar_filled_percentage, HEALTH_BAR_HEIGHT, 0, 0)
    sprite_batch:set_color(1, 1, 1, 1)
end

function Gravestone:update(map)
    -- Remove dead enemies, we only want to keep track of how many
    -- enemies we've spawned are still alive.
    for i = #self.spawned_enemies, 1, -1 do
        if self.spawned_enemies[i].is_dead then
            table.remove(self.spawned_enemies, i)
        end
    end

    if #self.spawned_enemies >= map.max_enemies_per_gravestone then
        return
    end

    local new_enemy = Enemy:new(self.x, self.y)
    table.insert(map.enemies, new_enemy)
    table.insert(self.spawned_enemies, new_enemy)
end

function Gravestone:take_damage(damage, particles)
    if self.is_dead then return end

    self.health = self.health - damage
    Particle.spawn_damage_particles(particles, self.x, self.y, Particle.TYPE_GRAVESTONE_LIGHT,
        Particle.TYPE_GRAVESTONE_DARK)

    if self.health <= 0 then
        self.is_dead = true
    end
end
