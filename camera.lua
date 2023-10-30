Camera = {}

function Camera:new(width, height)
    local camera = {
        x = 0,
        y = 0,
        width = width,
        height = height,
        canvas_width = width,
        canvas_height = height,
        canvas_scale = 1,
    }

    setmetatable(camera, self)
    self.__index = self

    return camera
end

function Camera:center_on(x, y)
    local offset_x = math.floor(self.canvas_width * 0.5)
    local offset_y = math.floor(self.canvas_height * 0.5)
    self.x = math.floor(x - offset_x)
    self.y = math.floor(y - offset_y)
end

function Camera:resize(width, height)
    local canvas_scale = math.min(width / self.width, height / self.height);
    -- Snap scaling to integer values only.
    canvas_scale = math.max(1.0, math.floor(canvas_scale))

    if self.canvas then self.canvas:release() end
    self.canvas_width, self.canvas_height = width / canvas_scale, height / canvas_scale
    self.canvas = love.graphics.newCanvas(self.canvas_width, self.canvas_height)
    self.canvas_scale = canvas_scale
end

function Camera:begin_draw_to()
    love.graphics.setCanvas(self.canvas)
    love.graphics.push()
    love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camera:end_draw_to()
    love.graphics.pop()
    love.graphics.setCanvas()
end

function Camera:draw()
    love.graphics.draw(self.canvas, 0, 0, 0, self.canvas_scale, self.canvas_scale)
end

function Camera:screen_to_world(x, y)
    local world_x = x / self.canvas_scale + self.x
    local world_y = y / self.canvas_scale + self.y

    return world_x, world_y
end