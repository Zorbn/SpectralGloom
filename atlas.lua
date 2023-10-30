Atlas = {}

function Atlas:load(image_path, info_path)
    self.image = love.graphics.newImage(image_path)
    self.sprites = {}

    local image_width = self.image:getWidth()
    local image_height = self.image:getHeight()

    for line in love.filesystem.lines(info_path) do
        local sections = line:gmatch("[^;]+")
        local name, x, y, width, height = sections(), sections(), sections(), sections(), sections()
        local quad = love.graphics.newQuad(x, y, width, height, image_width, image_height)
        self.sprites[name] = {
            quad = quad,
            width = width,
            height = height,
        }
    end
end