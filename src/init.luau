local Icon = require("@self/Icon")
local mount = require("@self/mount")
local types = require("@self/types")

export type IconProps = types.IconProps
export type Side = types.Side
export type MountOptions = mount.MountOptions

return {
	mount = mount,
	Icon = Icon,
}
