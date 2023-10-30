local RADIUS = 6
local DAMAGE = 20
local SPRITE = Atlas.sprites["Bullet"]
local MOVE_SPEED = 480
local COLOR_CHANGE_TIME = 0.15
local INVERSE_COLOR_CHANGE_TIME = 1.0 / COLOR_CHANGE_TIME
local SCALE_CHANGE_TIME = 0.2
local INVERSE_SCALE_CHANGE_TIME = 1.0 / SCALE_CHANGE_TIME
local ANIMATION_SCALE = 1.5
local SCALE_MIDPOINT = 0.15
local COLOR_R = 232 / 255
local COLOR_G = 193 / 255
local COLOR_B = 112 / 255

Bullet = {
    pool = {},
    allocation_count = 0,
}

function Bullet:new(x, y, angle)
    local bullet
    if #self.pool > 0 then
        bullet = table.remove(self.pool, #self.pool)
    else
        bullet = {}
        self.allocation_count = self.allocation_count + 1
    end

    bullet.x = x
    bullet.y = y
    bullet.angle = angle
    bullet.dx = math.cos(angle)
    bullet.dy = math.sin(angle)
    bullet.time = 0
    bullet.is_dead = false

    setmetatable(bullet, self)
    self.__index = self

    return bullet
end

function Bullet:recycle()
    table.insert(Bullet.pool, self)
end

function Bullet:update(dt, map)
    self.x = self.x + self.dx * MOVE_SPEED * dt
    self.y = self.y + self.dy * MOVE_SPEED * dt
    self.time = self.time + dt

    if self.x < 0 or self.x >= Map.WIDTH or self.y < 0 or self.y >= Map.HEIGHT then
        self.is_dead = true
        return
    end

    local nearby_enemies = map:nearby_enemies(self.x, self.y)
    for _, enemy in pairs(nearby_enemies) do
        local distance = GameMath.distance(self.x, self.y, enemy.x, enemy.y)

        if distance < RADIUS + Enemy.RADIUS then
            self.is_dead = true
            enemy:take_damage(DAMAGE, map.particles)
            return
        end
    end
end

function Bullet:draw(sprite_batch, _)
    local color_delta = math.min(self.time * INVERSE_COLOR_CHANGE_TIME, 1.0)
    local color_r = GameMath.lerp2(1, COLOR_R, color_delta)
    local color_g = GameMath.lerp2(1, COLOR_G, color_delta)
    local color_b = GameMath.lerp2(1, COLOR_B, color_delta)

    local scale_delta = math.min(self.time * INVERSE_SCALE_CHANGE_TIME, 1)
    local scale = GameMath.lerp3(1, ANIMATION_SCALE, 1, scale_delta, SCALE_MIDPOINT, true)
    sprite_batch:set_color(color_r, color_g, color_b, 1)
    sprite_batch:add_sprite(SPRITE, self.x, self.y, 0, self.angle, scale, scale)
    sprite_batch:set_color(1, 1, 1, 1)
end
