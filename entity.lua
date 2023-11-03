Entity = {}

function Entity.try_hit(self, radius, damage, other, other_radius, particles)
    local distance = GameMath.distance(self.x, self.y, other.x, other.y)

    if distance < radius + other_radius then
        other:take_damage(damage, particles)
        return true
    end

    return false
end