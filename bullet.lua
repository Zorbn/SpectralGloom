local Atlas = require("atlas")
local GameMath = require("game_math")

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

local Bullet = {}

function Bullet:new(x, y, angle)
    local bullet = {
        x = x,
        y = y,
        angle = angle,
        dx = math.cos(angle),
        dy = math.sin(angle),
        time = 0,
    }

    setmetatable(bullet, self)
    self.__index = self

    return bullet
end

function Bullet:update(dt)
    self.x = self.x + self.dx * MOVE_SPEED * dt
    self.y = self.y + self.dy * MOVE_SPEED * dt
    self.time = self.time + dt
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

return Bullet
