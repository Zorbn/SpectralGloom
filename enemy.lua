local Atlas = require("atlas")

local MOVE_SPEED = 80
local BOUNCE_SPEED = 9
local BOUNCE_HEIGHT = 8
local SQUASH_STRETCH = 0.1

local Enemy = {}

function Enemy:new(x, y)
    local enemy = {
        x = x,
        y = y,
        z = 0,
        scale_x = 1,
        scale_y = 1,
        time = 0,
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
    shadow_sprite_batch:add_shadow(Atlas.sprites["EvilPumpkin"], self.x, self.y, self.z, 0, self.scale_x, self.scale_y)

    sprite_batch:add_sprite(Atlas.sprites["EvilPumpkin"], self.x, self.y, self.z, 0, self.scale_x,
        self.scale_y)
end

return Enemy