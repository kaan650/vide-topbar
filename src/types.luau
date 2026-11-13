local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")

type Value<T> = VideFoundation.Value<T>

export type Side = "Left" | "Center" | "Right"

export type IconProps = {
	side: Value<Side>?,
	--- Icons are laid out left to right by `order`, on every side.
	order: Value<number>?,
	--- A Builder Icons name: "shopping-cart", or `Foundation.Enums.IconName.ShoppingCart`.
	icon: Value<string?>?,
	image: Value<Content?>?,
	label: Value<string?>?,
	--- A count, hidden at 0 and capped at 99 like Roblox's own, or `true` for a dot.
	badge: Value<number | boolean | nil>?,
	--- Shown under the icon once the pointer rests on it, like Roblox's own topbar tooltips.
	tooltip: Value<string?>?,
	--- Makes the icon a toggle: pressing it flips this source.
	selected: Vide.Source<boolean>?,
	isDisabled: Value<boolean>?,
	onActivated: (() -> ())?,
}

return {}
