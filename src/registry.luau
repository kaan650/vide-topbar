local RunService = game:GetService("RunService")

local Vide = require("./Packages/Vide")
local types = require("./types")

type IconProps = types.IconProps

local icons = Vide.source({} :: { [number]: IconProps })
local mounted = false
local warnedNotMounted = false
local nextId = 0

local function warnIfNotMounted()
	if mounted or warnedNotMounted or not RunService:IsStudio() then
		return
	end
	warnedNotMounted = true
	warn("VideTopbar: an icon was added but VideTopbar.mount() has not been called")
end

local registry = {}

--- Every icon added from any scope, by id. The mounted topbar renders them.
function registry.icons(): { [number]: IconProps }
	return icons()
end

function registry.add(props: IconProps): () -> ()
	nextId += 1
	local id = nextId
	local added = table.clone(Vide.untrack(icons))
	added[id] = props
	icons(added)
	task.defer(warnIfNotMounted)

	return function()
		local remaining = table.clone(Vide.untrack(icons))
		remaining[id] = nil
		icons(remaining)
	end
end

function registry.isMounted(): boolean
	return mounted
end

function registry.setMounted(value: boolean)
	mounted = value
end

return registry
