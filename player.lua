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
local PLAYER_HEIGHT = 32
local BULLET_SPRITE = Atlas.sprites["Bullet"]
local GUN_SPRITE = Atlas.sprites["Gun"]
local GUN_FIRING_SPRITE = Atlas.sprites["GunFiring"]
local GUN_X = -1
local GUN_Y_ANIMATIONS = {
    idle = {
        7
    },
    running = {
        6,
        7,
        6,
        7,
    },
}
local GUN_ORIGIN_X = 4
local GUN_ORIGIN_Y = 7
local MOVE_SPEED = 120
local ATTACK_COOLDOWN = 0.2
local MAX_HEALTH = 100
local HIT_INVINCIBILITY_TIME = 0.2
local HIT_SHOW_HEALTHBAR_TIME = 0.6

Player = {
    RADIUS = 16,
}

function Player:new(x, y)
    local player = {
        x = x,
        y = y,
        health = MAX_HEALTH,
        is_dead = false,
        hit_invincibility_timer = HIT_SHOW_HEALTHBAR_TIME,
        animator = Animator:new(ANIMATIONS, ANIMATION_SPEED),
        direction = 1,
        attack_cooldown_timer = ATTACK_COOLDOWN,
        gun = {
            animator = Animator:new(GUN_Y_ANIMATIONS, ANIMATION_SPEED),
            angle = 0,
            x = 0,
            y = 0,
        },
    }

    setmetatable(player, self)
    self.__index = self

    player.animator:play("idle")
    player.gun.animator:play("idle")

    return player
end

function Player:update(dt, camera, bullets)
    if self.is_dead then return end

    self.hit_invincibility_timer = self.hit_invincibility_timer + dt

    self.animator:update(dt)
    self.gun.animator:update(dt)

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
        self.x = GameMath.clamp(self.x, 0, Map.WIDTH)
        self.y = GameMath.clamp(self.y, 0, Map.HEIGHT)

        self.animator:play("running")
        self.gun.animator:play("running")
    else
        self.animator:play("idle")
        self.gun.animator:play("idle")
    end

    local mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x, mouse_y = camera:screen_to_world(mouse_x, mouse_y)
    self.gun.angle = math.atan2(mouse_y - self.gun.y, mouse_x - self.gun.x)

    if mouse_x < self.gun.x then
        self.direction = -1
    else
        self.direction = 1
    end

    self.attack_cooldown_timer = self.attack_cooldown_timer + dt

    if love.mouse.isDown(1) and self.attack_cooldown_timer > ATTACK_COOLDOWN then
        self:attack(bullets)
    end

    local gun_frame = self.gun.animator:frame()
    self.gun.x = self.x + GUN_X * self.direction
    self.gun.y = self.y + gun_frame
end

function Player:attack(bullets)
    self.attack_cooldown_timer = 0

    local new_bullet = Bullet:new(self.gun.x, self.gun.y, self.gun.angle)

    -- Move the bullet forward in front of the gun's barrel.
    new_bullet.x = new_bullet.x + new_bullet.dx * BULLET_SPRITE.width
    new_bullet.y = new_bullet.y + new_bullet.dy * BULLET_SPRITE.width

    -- Move the bullet upward towards the gun's barrel.
    local up_angle = self.gun.angle - math.pi * 0.5 * (self.direction > 0 and 1 or -1)
    local up_dx = math.cos(up_angle)
    local up_dy = math.sin(up_angle)
    new_bullet.x = new_bullet.x + up_dx * BULLET_SPRITE.height * 0.5
    new_bullet.y = new_bullet.y + up_dy * BULLET_SPRITE.height * 0.5

    table.insert(bullets, new_bullet)
end

function Player:draw(sprite_batch, shadow_sprite_batch)
    local frame = self.animator:frame()
    sprite_batch:add_sprite(frame, self.x, self.y, 0, 0, self.direction)
    shadow_sprite_batch:add_shadow(frame, self.x, self.y, 0, 0, self.direction)

    local gun_angle = self.gun.angle
    if self.direction < 0 then
        gun_angle = gun_angle - math.pi
    end

    local gun_sprite = GUN_SPRITE
    if self.attack_cooldown_timer < ATTACK_COOLDOWN * 0.5 then
        gun_sprite = GUN_FIRING_SPRITE
    end

    sprite_batch:add_sprite(gun_sprite, self.gun.x, self.gun.y, 0, gun_angle, self.direction, 1, GUN_ORIGIN_X,
        GUN_ORIGIN_Y)
    shadow_sprite_batch:add_shadow(gun_sprite, self.gun.x, self.gun.y, 0, gun_angle, self.direction, 1, GUN_ORIGIN_X,
        GUN_ORIGIN_Y)

    if self.hit_invincibility_timer < HIT_SHOW_HEALTHBAR_TIME then
        local health_bar_x = self.x - Healthbar.WIDTH * 0.5
        local health_bar_y = self.y + PLAYER_HEIGHT * 0.5
        Healthbar.draw(sprite_batch, health_bar_x, health_bar_y, self.health, MAX_HEALTH)
    end
end

function Player:take_damage(damage, particles)
    if self.is_dead then return end
    if self.hit_invincibility_timer < HIT_INVINCIBILITY_TIME then return end

    self.health = self.health - damage
    self.hit_invincibility_timer = 0
    Particle.spawn_damage_particles(particles, self.x, self.y, Particle.TYPE_PLAYER_LIGHT,
        Particle.TYPE_PLAYER_DARK)

    if self.health <= 0 then
        self.is_dead = true
    end
end