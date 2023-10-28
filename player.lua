local Atlas = require("atlas")
local Animator = require("animator")

local ANIMATION_SPEED = 10
local ANIMATIONS = {
    idle = {
        Atlas.sprites["Farmer"],
    },
    running = {
        Atlas.sprites["FarmerRunning1"],
        Atlas.sprites["Farmer"],
        Atlas.sprites["FarmerRunning3"],
        Atlas.sprites["Farmer"],
    },
}
local MOVE_SPEED = 120

local Player = {}

function Player:new(x, y)
    local player = {
        x = x,
        y = y,
        animator = Animator:new(ANIMATIONS, ANIMATION_SPEED),
        direction = 1,
    }
    player.animator:play("running")

    setmetatable(player, self)
    self.__index = self

    return player
end

function Player:update(dt)
    self.animator:update(dt)

    local motion_x = 0
    local motion_y = 0

    if love.keyboard.isScancodeDown("w") then motion_y = motion_y - 1 end
    if love.keyboard.isScancodeDown("a") then motion_x = motion_x - 1 end
    if love.keyboard.isScancodeDown("s") then motion_y = motion_y + 1 end
    if love.keyboard.isScancodeDown("d") then motion_x = motion_x + 1 end

    local motion_magnitude = math.sqrt(motion_x * motion_x + motion_y * motion_y)
    if motion_magnitude ~= 0 then
        motion_x = motion_x / motion_magnitude
        motion_y = motion_y / motion_magnitude

        self.x = self.x + motion_x * MOVE_SPEED * dt
        self.y = self.y + motion_y * MOVE_SPEED * dt

        if motion_x > 0 then
            self.direction = 1
        elseif motion_x < 0 then
            self.direction = -1
        end

        self.animator:play("running")
    else
        self.animator:play("idle")
    end
end

function Player:draw(sprite_batch, shadow_sprite_batch)
    local frame = self.animator:frame()
    sprite_batch:add_sprite(frame, self.x, self.y, 0, 0, self.direction)
    shadow_sprite_batch:add_shadow(frame, self.x, self.y, 0, self.direction)
end

return Player
