--* Input positions are in AbsolutePosition's space, as Foundation's isPointInGuiObjectBounds compares them.

--- Whether a point from an input lies on `object`.
local function isPointOn(object: GuiObject, point: Vector2): boolean
	local offset = point - object.AbsolutePosition
	local size = object.AbsoluteSize
	return offset.X >= 0 and offset.Y >= 0 and offset.X <= size.X and offset.Y <= size.Y
end

return isPointOn
