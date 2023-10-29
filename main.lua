local Atlas = require("atlas")
love.graphics.setDefaultFilter("nearest", "nearest")
Atlas:load("res/atlas.png", "res/atlasInfo.txt")

local SpriteBatch = require("sprite_batch")
local Player = require("player")
local GameMath = require("game_math")
local Camera = require("camera")

local VIEW_WIDTH, VIEW_HEIGHT = 640, 480
local BG_R, BG_G, BG_B = 52 / 255, 28 / 255, 39 / 255
local SHADOW_CANVAS_SHADER = love.graphics.newShader([[
const vec4 shadow_color = vec4(9.0, 10.0, 20.0, 120.0) / 255.0;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float texture_alpha = Texel(tex, texture_coords).a;
    vec4 texture_shadow_color = shadow_color;
    texture_shadow_color.a *= texture_alpha;

    return texture_shadow_color * color;
}
]])

local sprite_batch = SpriteBatch:new(Atlas.image, 1000)
local shadow_sprite_batch = SpriteBatch:new(Atlas.image, 1000)

local player = Player:new(170, 170)
local camera = Camera:new(VIEW_WIDTH, VIEW_HEIGHT)

local shadow_canvas
function love.resize(width, height)
    camera:resize(width, height)
    if shadow_canvas then shadow_canvas:release() end
    shadow_canvas = love.graphics.newCanvas(camera.canvas_width, camera.canvas_height)
end

love.resize(love.graphics.getDimensions())

local TILE_SIZE = 32
local DECORATION_RANGE = TILE_SIZE * 0.25
local MAP_WIDTH_TILES = 40
local MAP_HEIGHT_TILES = 20
local MAP_WIDTH = MAP_WIDTH_TILES * TILE_SIZE
local MAP_HEIGHT = MAP_HEIGHT_TILES * TILE_SIZE
local DECORATION_DENSITY = 0.15
local DECORATION_SPRITES = {
    [1] = Atlas.sprites["Weeds1"],
    [2] = Atlas.sprites["Weeds2"],
}

local function map_init(decorations)
    for y = 0, MAP_HEIGHT_TILES do
        for x = 0, MAP_WIDTH_TILES do
            if math.random() > DECORATION_DENSITY then
                goto continue
            end

            local decoration_x = x * TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_y = y * TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_type = math.random(1, 2)

            table.insert(decorations, {
                x = decoration_x,
                y = decoration_y,
                type = decoration_type,
            })

            ::continue::
        end
    end
end

math.randomseed(777)
local decorations = {}
map_init(decorations)
local bullets = {}
local BULLET_SPRITE = Atlas.sprites["Bullet"]
local BULLET_MOVE_SPEED = 480
local BULLET_COLOR_CHANGE_TIME = 0.15
local BULLET_INVERSE_COLOR_CHANGE_TIME = 1.0 / BULLET_COLOR_CHANGE_TIME
local BULLET_SCALE_CHANGE_TIME = 0.2
local BULLET_INVERSE_SCALE_CHANGE_TIME = 1.0 / BULLET_SCALE_CHANGE_TIME
local BULLET_ANIMATION_SCALE = 1.5
local BULLET_SCALE_MIDPOINT = 0.15
local BULLET_COLOR_R = 232 / 255
local BULLET_COLOR_G = 193 / 255
local BULLET_COLOR_B = 112 / 255

local time = 0
local PUMPKIN_X, PUMPKIN_Y, pumpkin_z = 100, 100, 0
local PUMPKIN_BOUNCE_SPEED = 9
local PUMPKIN_BOUNCE_HEIGHT = 8
local PUMPKIN_SQUASH_STRETCH = 0.1
local pumpkin_scale_x = 0
local pumpkin_scale_y = 0
function love.update(dt)
    time = time + dt
    local pumpkin_jump_progress = math.abs(math.sin(time * PUMPKIN_BOUNCE_SPEED))
    pumpkin_z = pumpkin_jump_progress * PUMPKIN_BOUNCE_HEIGHT
    local pumpkin_squash_stretch_progress = math.sin(time * PUMPKIN_BOUNCE_SPEED * 2)
    pumpkin_scale_x = 1 - pumpkin_squash_stretch_progress * PUMPKIN_SQUASH_STRETCH
    pumpkin_scale_y = 1 + pumpkin_squash_stretch_progress * PUMPKIN_SQUASH_STRETCH

    player:update(dt, camera, bullets)
    camera:center_on(player.x, player.y)

    for _, bullet in pairs(bullets) do
        bullet.x = bullet.x + bullet.dx * BULLET_MOVE_SPEED * dt
        bullet.y = bullet.y + bullet.dy * BULLET_MOVE_SPEED * dt
        bullet.time = bullet.time + dt
    end
end

function love.draw()
    camera:begin_draw_to()
    love.graphics.clear(BG_R, BG_G, BG_B)

    -- Draw ground decorations before everything else.
    sprite_batch:clear()

    for _, decoration in pairs(decorations) do
        sprite_batch:add_sprite(DECORATION_SPRITES[decoration.type], decoration.x, decoration.y, 0)
    end

    sprite_batch:draw()

    -- Now draw shadows and other sprites.
    sprite_batch:clear()
    shadow_sprite_batch:clear()

    shadow_sprite_batch:add_shadow(Atlas.sprites["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, 0, pumpkin_scale_x, pumpkin_scale_y)

    sprite_batch:add_sprite(Atlas.sprites["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, 0, pumpkin_scale_x,
        pumpkin_scale_y)

    player:draw(sprite_batch, shadow_sprite_batch)

    for i = #bullets, 1, -1 do
        local bullet = bullets[i]

        local bullet_color_delta = math.min(bullet.time * BULLET_INVERSE_COLOR_CHANGE_TIME, 1.0)
        local bullet_color_r = GameMath.lerp2(1, BULLET_COLOR_R, bullet_color_delta)
        local bullet_color_g = GameMath.lerp2(1, BULLET_COLOR_G, bullet_color_delta)
        local bullet_color_b = GameMath.lerp2(1, BULLET_COLOR_B, bullet_color_delta)

        local bullet_scale_delta = math.min(bullet.time * BULLET_INVERSE_SCALE_CHANGE_TIME, 1)
        local bullet_scale = GameMath.lerp3(1, BULLET_ANIMATION_SCALE, 1, bullet_scale_delta, BULLET_SCALE_MIDPOINT, true)
        sprite_batch:set_color(bullet_color_r, bullet_color_g, bullet_color_b, 1)
        sprite_batch:add_sprite(BULLET_SPRITE, bullet.x, bullet.y, 0, bullet.angle, bullet_scale, bullet_scale)
        sprite_batch:set_color(1, 1, 1, 1)

        if bullet.x < 0 or bullet.x >= MAP_WIDTH or bullet.y < 0 or bullet.y >= MAP_HEIGHT then
            table.remove(bullets, i)
        end
    end

    camera:end_draw_to()
    love.graphics.setCanvas(shadow_canvas)
    love.graphics.clear(0, 0, 0, 0)
    shadow_sprite_batch:draw(-camera.x, -camera.y)

    camera:begin_draw_to()
    love.graphics.setShader(SHADOW_CANVAS_SHADER)
    love.graphics.draw(shadow_canvas, camera.x, camera.y)
    love.graphics.setShader()

    sprite_batch:draw()
    camera:end_draw_to()

    camera:draw()

    -- love.graphics.print("hello world", 0, 0)
end
