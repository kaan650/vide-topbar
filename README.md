# VideTopbar

Topbar icons for [Vide](https://github.com/centau/vide), drawn like Roblox's own topbar with
[VideFoundation](https://github.com/kaan650/vide-foundation).

- Icons with Builder Icons glyphs or images, labels, badges and tooltips
- Keyboard shortcuts through the Input Action System, shown as keycaps in tooltips
- Menus that open as a list under an icon or slide out sideways, with lists inside lists
- Text fields that slide out of an icon, for codes or search
- Groups that share one pill, with dividers
- Icons that don't fit move into an overflow menu, and keep clear of other UI on the topbar
- Gamepad support, phone safe areas, room for the health bar, and the game's own translations

## Install

```toml
[dependencies]
VideTopbar = "kaan650/vide-topbar@0.1.0"
```

## Usage

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local VideTopbar = require(ReplicatedStorage.Packages.VideTopbar)

VideTopbar.mount()

local shopOpen = Vide.source(false)
local coins = Vide.source(0)

Vide.root(function()
	VideTopbar.Icon({
		order = 1,
		icon = "shopping-cart",
		label = "Shop",
		tooltip = "Open the shop",
		shortcut = Enum.KeyCode.B,
		selected = shopOpen,
	})

	VideTopbar.Icon({
		order = 2,
		icon = "three-bars-horizontal",
		tooltip = "Menu",
		menu = function()
			VideTopbar.Icon({
				order = 1,
				icon = "gear",
				label = "Settings",
				onActivated = function()
					print("Settings")
				end,
			})
			VideTopbar.Icon({ order = 2, icon = "trophy", label = "Quests", badge = 3 })
		end,
	})

	VideTopbar.Group({ order = 3 }, function()
		VideTopbar.Icon({ order = 1, icon = "heart", tooltip = "Like" })
		VideTopbar.Divider({ order = 2 })
		VideTopbar.Icon({ order = 3, icon = "bell", tooltip = "Inbox", badge = true })
	end)

	VideTopbar.Icon({
		side = "Right",
		label = function()
			return `{coins()} coins`
		end,
		minWidth = 120,
	})
end)
```

- An icon lives as long as the Vide scope that adds it: add it inside `Vide.root`, a component or `Vide.show`, and it
  leaves the topbar when that scope is destroyed.
- Props take a value or a source: `label = "Shop"`, `badge = notifications`, `isDisabled = function() ... end`.
- `selected` makes an icon a toggle that flips the source you pass; `menuOpen` opens and closes a menu from code.
- Icons added inside `menu` become its rows. A row with a `menu` of its own opens it in place of the list.
  `menuStyle = "Row"` opens the menu sideways instead, as icons on the topbar's pill.
- `input = { onSubmit = function(text) ... end }` gives an icon a text field that slides out of it like a row menu;
  Enter submits it. As a menu row, or in the overflow menu, it opens a page with the field.
- Images are `Content`: `image = Content.fromAssetId(123)`.
- `mount` returns a function that removes the topbar. It takes `displayOrder`, `enabled`, `colorMode`,
  `gamepadHighlightKey` (DPadUp by default) and `avoid`.
- `avoid` takes GUI objects that other code puts on the topbar, such as another library's icons. Icons keep to the
  widest stretch of the bar they leave free, and what no longer fits moves into the overflow menu.
- Shift doesn't work as a shortcut modifier in games with shift lock, since Roblox takes it first. Use Ctrl or Alt.

Every prop is documented in `src/types.luau`, and shows in your editor's autocomplete.

## Stories

Run `wally install` and `rojo serve dev.project.json`, then open the VideTopbar storybook in
[UI Labs](https://ui-labs.luau.page/), or press Play for a demo on the live topbar.

Foundation, Builder Icons and the topbar's look are made by Roblox.
