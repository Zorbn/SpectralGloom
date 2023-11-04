local table_clear = require("table.clear")

require("atlas")
love.graphics.setDefaultFilter("nearest", "nearest")
Atlas:load("res/atlas.png", "res/atlasInfo.txt")

require("animator")
require("bullet")
require("camera")
require("enemy")
require("game_math")
require("map")
require("particle")
require("player")
require("sprite_batch")
require("gravestone")
require("gravestone_destroyed")
require("healthbar")
require("entity")

local YOU_WIN_SPRITE = Atlas.sprites["YouWin"]
local RESTART_TIME = 3
local MAX_DELTA_TIME = 0.1
local VIEW_WIDTH, VIEW_HEIGHT = 640, 480
local BG_R, BG_G, BG_B = 16 / 255, 20 / 255, 31 / 255
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
local map_sprite_batch = SpriteBatch:new(Atlas.image, 1000)
local shadow_sprite_batch = SpriteBatch:new(Atlas.image, 1000)

local restart_timer = 0
local camera = Camera:new(VIEW_WIDTH, VIEW_HEIGHT)
local map
local function reset_map()
    map = Map:new()
    map:init()
    map_sprite_batch:clear()
    map:draw(map_sprite_batch)
end

math.randomseed(777)
reset_map()

local shadow_canvas
function love.resize(width, height)
    camera:resize(width, height)
    if shadow_canvas then shadow_canvas:release() end
    shadow_canvas = love.graphics.newCanvas(camera.canvas_width, camera.canvas_height)
end

love.resize(love.graphics.getDimensions())

local drawables = {}

local function sort_drawables(a, b)
    return a.y < b.y
end

function love.update(dt)
    -- Ignore massive delta time values caused by dragging the window, etc.
    if dt > MAX_DELTA_TIME then
        return
    end

    if map.state == Map.STATE_GAME_OVER then
        restart_timer = restart_timer + dt
        if restart_timer > RESTART_TIME then
            restart_timer = 0
            reset_map()
        end
    elseif map.state == Map.STATE_WIN then
        if love.keyboard.isDown("space") then
            reset_map()
        end
    end

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    table_clear(drawables)
    map:update(dt, drawables, camera)
    table.sort(drawables, sort_drawables)
end

function love.draw()
    camera:begin_draw_to()
    love.graphics.clear(BG_R, BG_G, BG_B)

    -- Draw ground decorations before everything else.
    map:draw(nil)
    map_sprite_batch:draw()

    -- Now draw shadows and other sprites.
    sprite_batch:clear()
    shadow_sprite_batch:clear()

    for _, drawable in ipairs(drawables) do
        if not drawable.is_dead then
            drawable:draw(sprite_batch, shadow_sprite_batch)
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

    if map.state == Map.STATE_WIN then
        love.graphics.draw(Atlas.image, YOU_WIN_SPRITE.quad,
            camera.x + camera.canvas_width * 0.5, camera.y + camera.canvas_height * 0.4,
            0, 1, 1, YOU_WIN_SPRITE.width * 0.5, YOU_WIN_SPRITE.height * 0.5)
    end

    camera:end_draw_to()

    camera:draw()

    -- love.graphics.print(math.floor(collectgarbage("count")) / 1000 .. "mb", 0, 0)
end
