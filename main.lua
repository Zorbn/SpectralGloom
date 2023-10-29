local table_clear = require("table.clear")

local Atlas = require("atlas")
love.graphics.setDefaultFilter("nearest", "nearest")
Atlas:load("res/atlas.png", "res/atlasInfo.txt")

local SpriteBatch = require("sprite_batch")
local Player = require("player")
local Camera = require("camera")
local Enemy = require("enemy")
local Map = require("map")
local Particle = require("particle")
local Bullet = require("bullet")

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

local DECORATION_RANGE = Map.TILE_SIZE * 0.25
local DECORATION_DENSITY = 0.15
local DECORATION_SPRITES = {
    [1] = Atlas.sprites["Weeds1"],
    [2] = Atlas.sprites["Weeds2"],
}

local function map_init(decorations, enemies)
    for y = 0, Map.HEIGHT_TILES do
        for x = 0, Map.WIDTH_TILES do
            if math.random() > DECORATION_DENSITY then
                goto continue
            end

            local decoration_x = x * Map.TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_y = y * Map.TILE_SIZE + (math.random() - 0.5) * DECORATION_RANGE
            local decoration_type = math.random(1, 2)

            table.insert(decorations, {
                x = decoration_x,
                y = decoration_y,
                type = decoration_type,
            })

            -- TODO:
            if math.random() > 0.2 then
                table.insert(enemies, Enemy:new(decoration_x, decoration_y))
            end

            ::continue::
        end
    end
end

math.randomseed(777)
local decorations = {}
local enemies = {}
map_init(decorations, enemies)
local bullets = {}
local particles = {}

local drawables = {}

local function sort_drawables(a, b)
    return a.y < b.y
end

function love.update(dt)
    -- print(love.timer.getFPS())

    table_clear(drawables)

    player:update(dt, camera, bullets)
    table.insert(drawables, player)
    camera:center_on(player.x, player.y)

    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        -- enemy:update(dt, player)

        if enemy.is_dead then
            table.remove(enemies, i)
        else
            table.insert(drawables, enemy)
        end
    end

    print("Particles:", Particle.allocation_count, "Bullets:", Bullet.allocation_count)

    -- local bullet_update_start = os.clock()
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update(dt, enemies, particles)

        if bullet.is_dead then
            table.remove(bullets, i)
            bullet:release()
        else
            table.insert(drawables, bullet)
        end
    end
    -- local bullet_update_end = os.clock()
    -- print("Bullet update: " .. (bullet_update_end - bullet_update_start) * 1000 .. "ms")

    for i = #particles, 1, -1 do
        local particle = particles[i]
        particle:update(dt)

        if particle.is_dead then
            table.remove(particles, i)
            particle:release()
        else
            table.insert(drawables, particle)
        end
    end

    table.sort(drawables, sort_drawables)
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
    camera:end_draw_to()

    camera:draw()

    -- love.graphics.print("hello world", 0, 0)
end
