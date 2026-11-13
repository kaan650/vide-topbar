local Vide = require("./Packages/Vide")

--- Where icons put what must draw over the whole bar, like tooltips. Set by `mount`.
local tooltipLayer = Vide.context(nil :: GuiObject?)

return {
	tooltipLayer = tooltipLayer,
}
