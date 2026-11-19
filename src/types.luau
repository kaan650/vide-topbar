local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")

type Value<T> = VideFoundation.Value<T>

export type Side = "Left" | "Center" | "Right"

--- How an icon's `menu` opens: a list under it, or a row of icons beside it on the topbar's pill.
export type MenuStyle = "List" | "Row"

--- A key, or up to two modifiers and then a key: `{ Enum.KeyCode.LeftControl, Enum.KeyCode.M }`.
--! Shift as a modifier never fires where the game offers shift lock: Roblox's MouseLockSwitchAction takes Shift before
--! the Input Action System sees it (tried at InputContext priority 100000 too). Use Ctrl or Alt.
export type Shortcut = Enum.KeyCode | { Enum.KeyCode }

export type IconProps = {
	--- Ignored inside a group or a menu, which place their icons themselves.
	side: Value<Side>?,
	--- Icons are laid out left to right by `order`, on every side, and top to bottom in a menu.
	order: Value<number>?,
	--- A Builder Icons name: "shopping-cart", or `Foundation.Enums.IconName.ShoppingCart`.
	icon: Value<string?>?,
	image: Value<Content?>?,
	--- How big `image` is drawn, against Roblox's 24 px glyphs.
	imageScale: Value<number?>?,
	--- `image`'s width over its height.
	imageRatio: Value<number?>?,
	label: Value<string?>?,
	--- Drawn inside the icon before its glyph and label. Called once inside the topbar, so Foundation's hooks work in
	--- it. Its AutoLocalize is left as it is, while the topbar's own text is translated like the game's other UI.
	leading: (() -> GuiObject)?,
	--- Drawn inside the icon after its label.
	trailing: (() -> GuiObject)?,
	--- The icon is at least this wide, its content centred. Keeps a label that changes (a counter, a timer) from moving
	--- the icons beside it.
	minWidth: Value<number?>?,
	--- A count, hidden at 0 and shown as 99+ past 99, `true` for a dot, or text. Text shows in a pill and a menu row; a
	--- round icon shows it as the dot. Hidden while the icon's menu is open, whose rows show their own.
	badge: Value<number | boolean | string | nil>?,
	--- Shown under the icon once the pointer rests on it, like Roblox's own topbar tooltips. Menu rows have none.
	tooltip: Value<string?>?,
	--- Activates the icon like a click, and is shown in its tooltip.
	shortcut: Value<Shortcut?>?,
	--- Shown in the tooltip like `shortcut` but not bound, for a key the game handles itself. Ignored while `shortcut`
	--- is set.
	shortcutHint: Value<Shortcut?>?,
	--- Makes the icon a toggle: pressing it flips this source.
	selected: Vide.Source<boolean>?,
	--- Unselects the icon, and closes its menu, whenever another icon is selected or opens its menu.
	autoDeselect: Value<boolean?>?,
	--- Ignores presses and shortcuts and dims the icon, as Foundation draws a disabled control.
	isDisabled: Value<boolean>?,
	--- Ignores presses and shortcuts without looking disabled.
	isLocked: Value<boolean?>?,
	onActivated: (() -> ())?,
	--- Makes the icon open a list under it, like Roblox's ⋯ menu. Icons added inside this function become its rows; a
	--- row with a `menu` of its own opens it in place of the list, with a row back at the top. While it is open the
	--- icon's glyph turns into an x, as Roblox's menu button does; a label stays as it is.
	menu: (() -> ())?,
	--- "Row" opens `menu` sideways instead: its icons slide out of this one onto a pill, as Roblox's Unibar was built
	--- to collapse and expand. It stays open until the icon is pressed again. Read once; not inside a group.
	menuStyle: MenuStyle?,
	--- Whether the menu is open, to open or close it from code. The icon writes it too.
	menuOpen: Vide.Source<boolean>?,
	--- Whether a click anywhere else closes the menu, as Roblox's does. True by default for a list and false for a row.
	closeOnOutsideClick: Value<boolean?>?,
	--- Makes the icon open a text field: on the topbar it slides out of the icon like a row menu, and as a menu row it
	--- opens in place of the list. Enter submits it. `menuOpen` and `closeOnOutsideClick` work as for a row menu.
	--- Read once; not with `menu`, inside a group or inside a row menu.
	input: InputOptions?,
}

export type InputOptions = {
	--- Called with the text when Enter is pressed. The field then empties and closes.
	onSubmit: (text: string) -> (),
	--- Shown while the field is empty; the icon's label, or else its tooltip, by default.
	placeholder: Value<string?>?,
	--- How wide the field is on the topbar, 200 by default.
	width: Value<number?>?,
}

export type GroupProps = {
	side: Value<Side>?,
	order: Value<number>?,
}

export type DividerProps = {
	order: Value<number>?,
}

return {}
