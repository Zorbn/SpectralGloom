local SPRITE = Atlas.sprites["Chunk"]
local MAX_VELOCITY_HORIZONTAL = 50
local MAX_VELOCITY_VERTICAL = 200
local GRAVITY = 800
local MAX_BOUNCES = 2

local DAMAGE_PARTICLE_COUNT = 3
local DAMAGE_PARTICLE_RADIUS = 16
local DAMAGE_PARTICLE_MIN_HEIGHT = 0
local DAMAGE_PARTICLE_MAX_HEIGHT = 32

Particle = {
    TYPE_PUMPKIN_LIGHT = 1,
    TYPE_PUMPKIN_DARK = 2,
    TYPE_GRAVESTONE_LIGHT = 3,
    TYPE_GRAVESTONE_DARK = 4,
    TYPE_PLAYER_LIGHT = 5,
    TYPE_PLAYER_DARK = 6,
    pool = {},
    allocation_count = 0,
}

local PARTICLE_COLORS = {
    [Particle.TYPE_PUMPKIN_LIGHT] = {
        r = 207 / 255,
        g = 87 / 255,
        b = 60 / 255,
    },
    [Particle.TYPE_PUMPKIN_DARK] = {
        r = 165 / 255,
        g = 48 / 255,
        b = 48 / 255,
    },
    [Particle.TYPE_GRAVESTONE_LIGHT] = {
        r = 57 / 255,
        g = 74 / 255,
        b = 80 / 255,
    },
    [Particle.TYPE_GRAVESTONE_DARK] = {
        r = 32 / 255,
        g = 46 / 255,
        b = 55 / 255,
    },
    [Particle.TYPE_PLAYER_LIGHT] = {
        r = 165 / 255,
        g = 48 / 255,
        b = 48 / 255,
    },
    [Particle.TYPE_PLAYER_DARK] = {
        r = 117 / 255,
        g = 36 / 255,
        b = 56 / 255,
    },
}

function Particle:new(x, y, z, angle, type)
    local particle
    if #self.pool > 0 then
        particle = table.remove(self.pool, #self.pool)
    else
        particle = {}
        self.allocation_count = self.allocation_count + 1
    end

    particle.x = x
    particle.y = y
    particle.z = z
    particle.vx = math.random(-MAX_VELOCITY_HORIZONTAL, MAX_VELOCITY_HORIZONTAL)
    particle.vy = math.random(-MAX_VELOCITY_HORIZONTAL, MAX_VELOCITY_HORIZONTAL)
    particle.vz = MAX_VELOCITY_VERTICAL
    particle.angle = angle
    particle.type = type
    particle.bounces = 0
    particle.is_dead = false

    setmetatable(particle, self)
    self.__index = self

    return particle
end

function Particle:recycle()
    table.insert(Particle.pool, self)
end

function Particle:update(dt)
    self.vz = self.vz - GRAVITY * dt

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.z = self.z + self.vz * dt

    if self.z < 0 then
        self.bounces = self.bounces + 1
        if self.bounces > MAX_BOUNCES then
            self.is_dead = true
            return
        end

        self.z = 0
        self.vz = -self.vz * 0.5
    end
end

function Particle:draw(sprite_batch, shadow_sprite_batch)
    local color = PARTICLE_COLORS[self.type]
    sprite_batch:set_color(color.r, color.g, color.b, 1)
    sprite_batch:add_sprite(SPRITE, self.x, self.y, self.z, self.angle, self.direction)
    sprite_batch:set_color(1, 1, 1, 1)
    shadow_sprite_batch:add_shadow(SPRITE, self.x, self.y, self.z, self.angle, self.direction)
end

function Particle.spawn_damage_particles(particles, x, y, min_type, max_type)
    for _ = 0, DAMAGE_PARTICLE_COUNT do
        local x = x + math.random(-DAMAGE_PARTICLE_RADIUS, DAMAGE_PARTICLE_RADIUS)
        local y = y + DAMAGE_PARTICLE_RADIUS
        local z = math.random(DAMAGE_PARTICLE_MIN_HEIGHT, DAMAGE_PARTICLE_MAX_HEIGHT)
        local angle = math.random() * math.pi * 2
        local type = math.random(min_type, max_type)
        table.insert(particles, Particle:new(x, y, z, angle, type))
    end
end