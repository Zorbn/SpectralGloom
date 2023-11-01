local GRAVESTONE_DESTROYED_SPRITE = Atlas.sprites["GravestoneDestroyed"]
local GRAVESTONE_DESTROYED_SHADOW_SHAPE_SPRITE = Atlas.sprites["GravestoneDestroyedShadowShape"]

GravestoneDestroyed = {}

function GravestoneDestroyed:new(x, y)
    local gravestone_destroyed = {
        x = x,
        y = y,
    }

    setmetatable(gravestone_destroyed, self)
    self.__index = self

    return gravestone_destroyed
end

function GravestoneDestroyed:draw(sprite_batch, shadow_sprite_batch)
    sprite_batch:add_sprite(GRAVESTONE_DESTROYED_SPRITE, self.x, self.y, 0, 0)
    shadow_sprite_batch:add_shadow(GRAVESTONE_DESTROYED_SHADOW_SHAPE_SPRITE, self.x, self.y, 0, 0)
end