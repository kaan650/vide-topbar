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
	--- Makes the icon a toggle: pressing it flips this source.
	selected: Vide.Source<boolean>?,
	isDisabled: Value<boolean>?,
	onActivated: (() -> ())?,
}

return {}
