local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")

type Value<T> = VideFoundation.Value<T>

--- The part of `object` that is drawn, in AbsolutePosition's space: nil unless it and every GuiObject above it are
--- visible under an enabled LayerCollector, and cut to the ancestors that clip their descendants.
local function drawnRect(object: GuiObject): Rect?
	local min = object.AbsolutePosition
	local max = min + object.AbsoluteSize
	local current: Instance? = object
	while current do
		if current:IsA("LayerCollector") then
			if not current.Enabled then
				return nil
			end
			break
		elseif current:IsA("GuiObject") then
			if not current.Visible then
				return nil
			end
			--* An icon library can keep a closed menu's items inside the icon and clip them away; they are on the
			--* strip but not drawn.
			if current ~= object and current.ClipsDescendants then
				min = min:Max(current.AbsolutePosition)
				max = max:Min(current.AbsolutePosition + current.AbsoluteSize)
			end
		end
		current = current.Parent
	end
	if current == nil or max.X <= min.X or max.Y <= min.Y then
		return nil
	end
	return Rect.new(min, max)
end

--- Calls `changed` whenever `object` moves, resizes, or is shown, hidden or clipped, by itself or through an ancestor.
local function watch(object: GuiObject, changed: () -> ())
	local chain: { RBXScriptConnection } = {}
	local function unwire()
		for _, connection in chain do
			connection:Disconnect()
		end
		table.clear(chain)
	end
	local function wire()
		unwire()
		local current: Instance? = object
		while current do
			if current:IsA("LayerCollector") then
				table.insert(chain, current:GetPropertyChangedSignal("Enabled"):Connect(changed))
				break
			elseif current:IsA("GuiObject") then
				table.insert(chain, current:GetPropertyChangedSignal("Visible"):Connect(changed))
				if current ~= object then
					table.insert(chain, current:GetPropertyChangedSignal("ClipsDescendants"):Connect(changed))
					table.insert(chain, current:GetPropertyChangedSignal("AbsoluteSize"):Connect(changed))
				end
			end
			current = current.Parent
		end
	end

	wire()
	Vide.cleanup(unwire)
	Vide.cleanup(object.AncestryChanged:Connect(function()
		wire()
		changed()
		--! AbsolutePosition can change after a reparent without firing its signal (see trackAbsolute), so this looks
		--! again once the move has settled.
		task.defer(changed)
	end))
	Vide.cleanup(object:GetPropertyChangedSignal("AbsolutePosition"):Connect(changed))
	Vide.cleanup(object:GetPropertyChangedSignal("AbsoluteSize"):Connect(changed))
end

--- The widest stretch of the bar, `bar` from left to right, that `avoid`'s objects leave free: where it starts and
--- ends in the space of the layer at `origin`, nil where it reaches the bar's end. Only what is drawn of each object
--- counts, and only where it reaches into the icons' strip, `stripTop` to `stripBottom`, so a dropdown hanging under
--- the topbar doesn't push the icons aside.
local function useFreeGap(
	avoid: Value<{ GuiObject }>,
	origin: () -> Vector2,
	strip: () -> (number, number),
	bar: () -> (number, number)
): (() -> number?, () -> number?)
	local function objects(): { GuiObject }
		return if type(avoid) == "function" then avoid() else avoid
	end

	local version = Vide.source(0)
	local function changed()
		version(Vide.untrack(version) + 1)
	end
	Vide.effect(function()
		for _, object in objects() do
			watch(object, changed)
		end
	end)

	--- Each object's left and right edge on the strip, as X and Y, sorted from the left.
	local function spans(): { Vector2 }
		local layer = origin()
		local stripTop, stripBottom = strip()
		local list: { Vector2 } = {}
		for _, object in objects() do
			local rect = drawnRect(object)
			if rect == nil then
				continue
			end
			local min = rect.Min - layer
			local max = rect.Max - layer
			if min.Y < stripBottom and max.Y > stripTop then
				table.insert(list, Vector2.new(min.X, max.X))
			end
		end
		table.sort(list, function(a: Vector2, b: Vector2): boolean
			return a.X < b.X
		end)
		return list
	end

	--* The widest gap rather than a side per object: a library whose icons fill the bar runs them from its left end
	--* past the middle (172 to 1520 px of a 1920 px screen, as one pill or as single icons), so neither an object's
	--* centre nor its nearer end says which icons it holds back.
	local function widestGap(): (number?, number?)
		version()
		local barLeft, barRight = bar()
		local bestFrom: number?, bestTo: number? = nil, nil
		local bestWidth = -math.huge
		local function consider(from: number?, to: number?)
			local width = (to or barRight) - (from or barLeft)
			if width > bestWidth then
				bestWidth = width
				bestFrom, bestTo = from, to
			end
		end

		local covered: number? = nil
		for _, span in spans() do
			if covered == nil or span.X > covered then
				consider(covered, span.X)
			end
			covered = math.max(covered or -math.huge, span.Y)
		end
		if covered ~= nil then
			consider(covered, nil)
		end
		return bestFrom, bestTo
	end

	local from: () -> number? = Vide.derive(function(): number?
		return (widestGap())
	end)
	local to: () -> number? = Vide.derive(function(): number?
		local _, gapEnd = widestGap()
		return gapEnd
	end)
	return from, to
end

return useFreeGap
