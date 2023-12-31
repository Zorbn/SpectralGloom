GameMath = {}

function GameMath.lerp2(a, b, delta, is_smooth)
    if is_smooth then
        -- Add easing by modifying the delta.
        delta = delta * delta * (3 - 2 * delta)
    end

    return a + (b - a) * delta
end

function GameMath.lerp3(a, b, c, delta, midpoint, is_smooth)
    midpoint = midpoint or 0.5

    if delta < midpoint then
        return GameMath.lerp2(a, b, delta / midpoint, is_smooth)
    end

    return GameMath.lerp2(b, c, (delta - midpoint) / (1.0 - midpoint), is_smooth)
end

function GameMath.distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function GameMath.clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

function GameMath.index_2d_to_1d(x, y, width)
    return x + (y - 1) * width
end