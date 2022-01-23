
local util = {}

function util.add(pos1, pos2)
    local x = (pos1.x or pos1[1]) + (pos2.x or pos2[1])
    local y = (pos1.y or pos1[2]) + (pos2.y or pos2[2])
    return {x=x, y=y}
end
function util.sub(pos1, pos2)
    local x = (pos1.x or pos1[1]) - (pos2.x or pos2[1])
    local y = (pos1.y or pos1[2]) - (pos2.y or pos2[2])
    return {x=x, y=y}
end

function util.serialize_area_box(box)
    local leftTop = box.left_top or box[1]
    local rightBottom = box.right_bottom or box[2]
    local size = util.sub(rightBottom, leftTop)
    -- round to 2 decimal places remove differences between loading and runtime floating point inaccuracies
    local size_string = {
        x = string.format("%.2f", size.x),
        y = string.format("%.2f", size.y)
    }
    return (size_string.x .. ":" .. size_string.y):gsub("[.]", "'")
end

return util