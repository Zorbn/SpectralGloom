local SQUARE_SPRITE = Atlas.sprites["Square"]

local HEALTH_BAR_HEIGHT = 4

local HEALTH_BAR_BG_R = 16 / 255
local HEALTH_BAR_BG_G = 20 / 255
local HEALTH_BAR_BG_B = 31 / 255

local HEALTH_BAR_FG_R = 117 / 255
local HEALTH_BAR_FG_G = 167 / 255
local HEALTH_BAR_FG_B = 67 / 255

local HEALTH_BAR_PADDING = 1
local DOUBLE_HEALTH_BAR_PADDING = HEALTH_BAR_PADDING * 2

Healthbar = {
    WIDTH = 32,
}

function Healthbar.draw(sprite_batch, x, y, health, max_health)
    local health_bar_filled_percentage = math.max(health / max_health, 0)

    sprite_batch:set_color(HEALTH_BAR_BG_R, HEALTH_BAR_BG_G, HEALTH_BAR_BG_B, 1)
    sprite_batch:add_sprite(SQUARE_SPRITE, x, y, 0, 0,
        Healthbar.WIDTH, HEALTH_BAR_HEIGHT, 0, 0)
    sprite_batch:set_color(HEALTH_BAR_FG_R, HEALTH_BAR_FG_G, HEALTH_BAR_FG_B, 1)
    sprite_batch:add_sprite(SQUARE_SPRITE, x + HEALTH_BAR_PADDING, y + HEALTH_BAR_PADDING, 0, 0,
        Healthbar.WIDTH * health_bar_filled_percentage - DOUBLE_HEALTH_BAR_PADDING,
        HEALTH_BAR_HEIGHT - DOUBLE_HEALTH_BAR_PADDING, 0, 0)
    sprite_batch:set_color(1, 1, 1, 1)
end
