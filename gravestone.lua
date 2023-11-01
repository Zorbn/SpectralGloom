local GRAVESTONE_SPRITE = Atlas.sprites["Gravestone"]
local GRAVESTONE_SHADOW_SHAPE_SPRITE = Atlas.sprites["GravestoneShadowShape"]

-- local SPAWN_COOLDOWN = 0.5

Gravestone = {
    RADIUS = 16,
}

function Gravestone:new(x, y)
    local gravestone = {
        x = x,
        y = y,
        spawned_enemies = {},
        -- spawn_cooldown_timer = 0,
        health = 1000,
        is_dead = false,
    }

    setmetatable(gravestone, self)
    self.__index = self

    return gravestone
end

function Gravestone:draw(sprite_batch, shadow_sprite_batch)
    sprite_batch:add_sprite(GRAVESTONE_SPRITE, self.x, self.y, 0, 0)
    shadow_sprite_batch:add_shadow(GRAVESTONE_SHADOW_SHAPE_SPRITE, self.x, self.y, 0, 0)
end

function Gravestone:update(map)
    -- self.spawn_cooldown_timer = self.spawn_cooldown_timer - dt

    -- if self.spawn_cooldown_timer > 0 then
    --     return
    -- end

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
    Particle.spawn_damage_particles(particles, self.x, self.y, Particle.TYPE_GRAVESTONE_LIGHT, Particle.TYPE_GRAVESTONE_DARK)

    if self.health <= 0 then
        self.is_dead = true
    end
end