--* The Wally dependency, a sibling of this package's root in Packages/_Index or in the dev place's Packages.
local VideFoundation = require(script.Parent.Parent.Parent.VideFoundation)

export type Value<T> = VideFoundation.Value<T>
export type ColorMode = VideFoundation.ColorMode
export type ControlState = VideFoundation.ControlState
export type Device = VideFoundation.Device

return VideFoundation
