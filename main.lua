local Atlas = require("atlas")
love.graphics.setDefaultFilter("nearest", "nearest")
Atlas:load("res/atlas.png", "res/atlasInfo.txt")

local SpriteBatch = require("sprite_batch")
local Player = require("player")

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

local canvas, shadow_canvas
local canvas_scale = 1
function love.resize(width, height)
    local view_scale = math.min(width / VIEW_WIDTH, height / VIEW_HEIGHT);
    -- Snap scaling to integer values only.
    view_scale = math.max(1.0, math.floor(view_scale))

    if canvas then canvas:release() end
    local canvas_width, canvas_height = width / view_scale, height / view_scale
    canvas = love.graphics.newCanvas(canvas_width, canvas_height)
    shadow_canvas = love.graphics.newCanvas(canvas_width, canvas_height)
    canvas_scale = view_scale
end

love.resize(love.graphics.getDimensions())

local TILE_SIZE = 32
local DECORATION_RANGE = TILE_SIZE * 0.25
local MAP_WIDTH = 40
local MAP_HEIGHT = 20
local DECORATION_DENSITY = 0.15
local DECORATION_SPRITES = {
    [1] = Atlas.sprites["Weeds1"],
    [2] = Atlas.sprites["Weeds2"],
}

local function map_init(decorations)
    for y = 0, MAP_HEIGHT do
        for x = 0, MAP_WIDTH do
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

    player:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
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

    shadow_sprite_batch:add_shadow(Atlas.sprites["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, pumpkin_scale_x, pumpkin_scale_y)

    sprite_batch:add_sprite(Atlas.sprites["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, 0, pumpkin_scale_x,
        pumpkin_scale_y)

    player:draw(sprite_batch, shadow_sprite_batch)

    love.graphics.setCanvas(shadow_canvas)
    love.graphics.clear(0, 0, 0, 0)
    shadow_sprite_batch:draw()

    love.graphics.setCanvas(canvas)
    love.graphics.setShader(SHADOW_CANVAS_SHADER)
    love.graphics.draw(shadow_canvas)
    love.graphics.setShader()

    sprite_batch:draw()
    love.graphics.setCanvas()

    love.graphics.draw(canvas, 0, 0, 0, canvas_scale, canvas_scale)

    love.graphics.print("hello world", 0, 0)
end
