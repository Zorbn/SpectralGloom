-- TODO: Make this into more of a tower defense game instead.

local function load_atlas(image_path, info_path)
    local atlas_image = love.graphics.newImage(image_path)
    local atlas_image_width = atlas_image:getWidth()
    local atlas_image_height = atlas_image:getHeight()
    local atlas_info = {}

    for line in love.filesystem.lines(info_path) do
        local sections = line:gmatch("[^;]+")
        local name, x, y, width, height = sections(), sections(), sections(), sections(), sections()
        local quad = love.graphics.newQuad(x, y, width, height, atlas_image_width, atlas_image_height)
        atlas_info[name] = {
            quad = quad,
            width = width,
            height = height,
        }
    end

    return atlas_image, atlas_info
end

love.graphics.setDefaultFilter("nearest", "nearest")

local ATLAS_IMAGE, ATLAS_INFO = load_atlas("res/atlas.png", "res/atlasInfo.txt")
local VIEW_WIDTH, VIEW_HEIGHT = 320, 240
local SCALE = 2
local BG_R, BG_G, BG_B = 52 / 255, 28 / 255, 39 / 255
local SHADOW_SHADER = love.graphics.newShader([[
const vec4 shadow_color = vec4(9.0, 10.0, 20.0, 120.0) / 255.0;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float texture_alpha = Texel(tex, texture_coords).a;
    vec4 texture_shadow_color = shadow_color;
    texture_shadow_color.a *= texture_alpha;

    return texture_shadow_color * color;
}
]])

local canvas = love.graphics.newCanvas(VIEW_WIDTH, VIEW_HEIGHT)
local sprite_batch = love.graphics.newSpriteBatch(ATLAS_IMAGE, 1000)

local function add_sprite(sprite_batch, sprite, x, y, z, r, scale_x, scale_y)
    sprite_batch:add(sprite.quad, x, y - z, r, scale_x, scale_y, sprite.width * 0.5, sprite.height * 0.5)
end

local SHADOW_ROTATION = math.pi * (1 - 0.15)
local SHADOW_SCALE_X = -1
local SHADOW_SCALE_Y = 0.9
local SHADOW_HEIGHT_SCALE = 0.01
local function add_shadow(sprite_batch, sprite, x, y, z, scale_x, scale_y)
    local offset_x = sprite.width * 0.15
    local offset_y = sprite.height * 0.4
    -- local rotated_offset_x = offset_x * math.cos(r) - offset_y * math.sin(r)
    -- local rotated_offset_y = offset_x * math.sin(r) + offset_y * math.cos(r)
    local height_scale = z * SHADOW_HEIGHT_SCALE
    local shadow_scale_x = scale_x * (SHADOW_SCALE_X + height_scale)
    local shadow_scale_y = scale_y * (SHADOW_SCALE_Y - height_scale)
    sprite_batch:add(sprite.quad, x + offset_x, y + offset_y, SHADOW_ROTATION, shadow_scale_x, shadow_scale_y, sprite.width * 0.5, sprite.height * 0.5)
end

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
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(BG_R, BG_G, BG_B)

    sprite_batch:clear()
    -- sprite_batch:add(ATLAS_INFO["EvilPumpkin"], PLAYER_X + 16, PLAYER_Y + 48, -0.125 * math.pi, 1, -1)
    add_shadow(sprite_batch, ATLAS_INFO["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, pumpkin_scale_x, pumpkin_scale_y)

    love.graphics.setShader(SHADOW_SHADER)
    love.graphics.draw(sprite_batch, 0, 0, 0)
    love.graphics.setShader()

    sprite_batch:clear()
    add_sprite(sprite_batch, ATLAS_INFO["EvilPumpkin"], PUMPKIN_X, PUMPKIN_Y, pumpkin_z, 0, pumpkin_scale_x, pumpkin_scale_y)

    love.graphics.draw(sprite_batch, 0, 0, 0)

    love.graphics.setCanvas()
    love.graphics.draw(canvas, 0, 0, 0, SCALE, SCALE)

    love.graphics.print("hello world", 0, 0)
end