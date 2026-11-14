local types = require("../types")

--* Foundation's DISABLED_TRANSPARENCY (Constants.luau): its Button fades its content this far while disabled.
local DISABLED_TRANSPARENCY = 0.5

--- Whether an icon's `isDisabled` is on.
local function isDisabled(props: types.IconProps): boolean
	local value = props.isDisabled
	return (if type(value) == "function" then value() else value) == true
end

--- `transparency` faded as Foundation fades a disabled control's content.
local function dimmed(transparency: number, disabled: boolean): number
	return if disabled then transparency + (1 - transparency) * DISABLED_TRANSPARENCY else transparency
end

return {
	isDisabled = isDisabled,
	dimmed = dimmed,
}
