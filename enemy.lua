local Atlas = require("atlas")
local Particle = require("particle")

local SPRITE = Atlas.sprites["EvilPumpkin"]
local MOVE_SPEED = 80
local BOUNCE_SPEED = 9
local BOUNCE_HEIGHT = 8
local SQUASH_STRETCH = 0.1
local DAMAGE_PARTICLE_COUNT = 3
local DAMAGE_PARTICLE_RADIUS = SPRITE.width * 0.5
local DAMAGE_PARTICLE_MIN_HEIGHT = 0
local DAMAGE_PARTICLE_MAX_HEIGHT = SPRITE.height

local Enemy = {
    RADIUS = 16,
}

function Enemy:new(x, y)
    local enemy = {
        x = x,
        y = y,
        z = 0,
        scale_x = 1,
        scale_y = 1,
        time = 0,
        is_dead = false,
        health = 100,
    }

    setmetatable(enemy, self)
    self.__index = self

    return enemy
end

function Enemy:update(dt, player)
    self.time = self.time + dt
    local jump_progress = math.abs(math.sin(self.time * BOUNCE_SPEED))
    self.z = jump_progress * BOUNCE_HEIGHT
    local squash_stretch_progress = math.sin(self.time * BOUNCE_SPEED * 2)
    self.scale_x = 1 - squash_stretch_progress * SQUASH_STRETCH
    self.scale_y = 1 + squash_stretch_progress * SQUASH_STRETCH

    local motion_x = player.x - self.x
    local motion_y = player.y - self.y
    local motion_magnitude = math.sqrt(motion_x * motion_x + motion_y * motion_y)
    if motion_magnitude ~= 0 then
        motion_x = motion_x / motion_magnitude
        motion_y = motion_y / motion_magnitude

        self.x = self.x + motion_x * MOVE_SPEED * dt
        self.y = self.y + motion_y * MOVE_SPEED * dt
    end
end

function Enemy:draw(sprite_batch, shadow_sprite_batch)
    shadow_sprite_batch:add_shadow(SPRITE, self.x, self.y, self.z, 0, self.scale_x, self.scale_y)

    sprite_batch:add_sprite(SPRITE, self.x, self.y, self.z, 0, self.scale_x,
        self.scale_y)
end

function Enemy:take_damage(damage, particles)
    if self.is_dead then return end

    self.health = self.health - damage
    for _ = 0, DAMAGE_PARTICLE_COUNT do
        local x = self.x + math.random(-DAMAGE_PARTICLE_RADIUS, DAMAGE_PARTICLE_RADIUS)
        local y = self.y + DAMAGE_PARTICLE_RADIUS
        local z = math.random(DAMAGE_PARTICLE_MIN_HEIGHT, DAMAGE_PARTICLE_MAX_HEIGHT)
        local angle = math.random() * math.pi * 2
        table.insert(particles, Particle:new(x, y, z, angle))
    end

    if self.health <= 0 then
        self.is_dead = true
    end
end

return Enemy