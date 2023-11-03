local SPRITE = Atlas.sprites["EvilPumpkin"]
local MOVE_SPEED = 80
local BOUNCE_SPEED = 9
local BOUNCE_HEIGHT = 8
local SQUASH_STRETCH = 0.1
local DAMAGE = 10

Enemy = {
    RADIUS = 16,
}

function Enemy:new(x, y)
    local enemy = {
        x = x,
        y = y,
        z = 0,
        dx = 0,
        dy = 0,
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

function Enemy:update(dt, map)
    self.time = self.time + dt
    local jump_progress = math.abs(math.sin(self.time * BOUNCE_SPEED))
    self.z = jump_progress * BOUNCE_HEIGHT
    local squash_stretch_progress = math.sin(self.time * BOUNCE_SPEED * 2)
    self.scale_x = 1 - squash_stretch_progress * SQUASH_STRETCH
    self.scale_y = 1 + squash_stretch_progress * SQUASH_STRETCH

    local motion_x = map.player.x - self.x
    local motion_y = map.player.y - self.y
    local motion_magnitude = math.sqrt(motion_x * motion_x + motion_y * motion_y)
    if motion_magnitude ~= 0 then
        motion_x = motion_x / motion_magnitude
        motion_y = motion_y / motion_magnitude

        self.x = self.x + motion_x * MOVE_SPEED * dt
        self.y = self.y + motion_y * MOVE_SPEED * dt
    end

    local combined_radius = Enemy.RADIUS * 2
    local nearby_enemies = map:nearby_enemies(self.x, self.y)
    for _, enemy in pairs(nearby_enemies) do
        if enemy == self then
            goto continue
        end

        local distance = GameMath.distance(self.x, self.y, enemy.x, enemy.y)
        if distance < combined_radius then
            local angle = math.atan2(enemy.y - self.y, enemy.x - self.x)
            local repel_power = (combined_radius - distance) / combined_radius
            local dx = math.cos(angle) * repel_power
            local dy = math.sin(angle) * repel_power
            self.x = self.x - dx
            self.y = self.y - dy
            enemy.x = enemy.x + dx
            enemy.y = enemy.y + dy
            -- NOTE: It would be better to set the velocities of self/enemy here
            -- so that they can move on their own and perform their own collisions,
            -- but this will work for now.
            enemy.x = GameMath.clamp(enemy.x, 0, Map.WIDTH)
            enemy.y = GameMath.clamp(enemy.y, 0, Map.HEIGHT)
        end

        ::continue::
    end

    self.x = GameMath.clamp(self.x, 0, Map.WIDTH)
    self.y = GameMath.clamp(self.y, 0, Map.HEIGHT)

    Entity.try_hit(self, Enemy.RADIUS, DAMAGE, map.player, Player.RADIUS, map.particles)
end

function Enemy:draw(sprite_batch, shadow_sprite_batch)
    shadow_sprite_batch:add_shadow(SPRITE, self.x, self.y, self.z, 0, self.scale_x, self.scale_y)

    sprite_batch:add_sprite(SPRITE, self.x, self.y, self.z, 0, self.scale_x,
        self.scale_y)
end

function Enemy:take_damage(damage, particles)
    if self.is_dead then return end

    self.health = self.health - damage
    Particle.spawn_damage_particles(particles, self.x, self.y, Particle.TYPE_PUMPKIN_LIGHT, Particle.TYPE_PUMPKIN_DARK)

    if self.health <= 0 then
        self.is_dead = true
    end
end
