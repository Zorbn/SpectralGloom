local Animator = {}

function Animator:new(animations, animation_speed)
    local animator = {
        animations = animations,
        animation_speed = animation_speed,
        animation_time = 0,
        animation_frame = 1,
        animation = nil,
    }

    setmetatable(animator, self)
    self.__index = self

    return animator
end

function Animator:update(dt)
    self.animation_time = self.animation_time + dt
    if self.animation_time * self.animation_speed > 1 then
        self.animation_time = 0

        self.animation_frame = self.animation_frame + 1
        if self.animation_frame > #self.animation then
            self.animation_frame = 1
        end
    end
end

function Animator:play(name)
    local new_animation = self.animations[name]
    if self.animation == new_animation then
        return
    end

    self.animation = new_animation
    self.animation_time = 0
    self.animation_frame = 1
end

function Animator:frame()
    return self.animation[self.animation_frame]
end

return Animator