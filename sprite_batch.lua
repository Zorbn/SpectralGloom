local SpriteBatch = {}

function SpriteBatch:new(image, max_sprites)
    local sprite_batch = {}

    setmetatable(sprite_batch, self)
    self.__index = self

    sprite_batch.batch = love.graphics.newSpriteBatch(image, max_sprites)

    return sprite_batch
end

function SpriteBatch:add_sprite(sprite, x, y, z, r, scale_x, scale_y)
    self.batch:add(sprite.quad, x, y - z, r or 0, scale_x or 1, scale_y or 1, sprite.width * 0.5, sprite.height * 0.8)
end

local SHADOW_ROTATION = math.pi * (1 - 0.15)
local SHADOW_SCALE_X = -1
local SHADOW_SCALE_Y = 0.9
local SHADOW_HEIGHT_SCALE = 0.01

function SpriteBatch:add_shadow(sprite, x, y, z, scale_x, scale_y)
    scale_x = scale_x or 1
    scale_y = scale_y or 1

    local offset_x = sprite.width * 0.15
    local offset_y = sprite.height * 0.4
    -- local rotated_offset_x = offset_x * math.cos(r) - offset_y * math.sin(r)
    -- local rotated_offset_y = offset_x * math.sin(r) + offset_y * math.cos(r)
    local height_scale = z * SHADOW_HEIGHT_SCALE
    local shadow_scale_x = scale_x * (SHADOW_SCALE_X + height_scale)
    local shadow_scale_y = scale_y * (SHADOW_SCALE_Y - height_scale)
    self.batch:add(sprite.quad, x + offset_x, y + offset_y, SHADOW_ROTATION, shadow_scale_x, shadow_scale_y,
        sprite.width * 0.5, sprite.height * 0.5)
end

function SpriteBatch:clear()
    self.batch:clear()
end

function SpriteBatch:draw()
    love.graphics.draw(self.batch)
end

return SpriteBatch