
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

function util.serializeBoundingBox(boundingBox)
    local leftTop = boundingBox.left_top or boundingBox[1]
    local rightBottom = boundingBox.right_bottom or boundingBox[2]
    local size = util.sub(rightBottom, leftTop)
    return (size.x .. ":" .. size.y):gsub("[.]", "'")
end

return util