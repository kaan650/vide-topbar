local Vide = require("./Packages/Vide")
local VideFoundation = require("./Packages/VideFoundation")
local types = require("./types")

local DEFAULT_WIDTH = 200

--- What an icon's field shows while empty: its own placeholder, or the icon's label, or else its tooltip.
local function placeholderOf(props: types.IconProps): string?
	local input = props.input
	local placeholder = if input then input.placeholder else nil
	local text = if type(placeholder) == "function" then placeholder() else placeholder
	if text ~= nil and text ~= "" then
		return text
	end
	local label = props.label
	text = if type(label) == "function" then label() else label
	if text ~= nil and text ~= "" then
		return text
	end
	local tooltip = props.tooltip
	return if type(tooltip) == "function" then tooltip() else tooltip
end

--- How wide an icon's field is on the topbar.
local function widthOf(input: types.InputOptions): number
	local value = input.width
	return (if type(value) == "function" then value() else value) or DEFAULT_WIDTH
end

--- An icon's text field: Foundation's TextInput without its label. It takes focus whenever `isOpen` turns true and lets
--- go when it turns false. Enter hands the text, unless empty, to `onSubmit`, empties the field and calls `close`.
local function InputFieldView(props: {
	icon: types.IconProps,
	size: VideFoundation.InputSize,
	width: () -> UDim,
	isOpen: () -> boolean,
	close: () -> (),
}): GuiObject
	local input = props.icon.input :: types.InputOptions
	local text = Vide.source("")
	local ref: VideFoundation.TextInputRef? = nil

	--* A frame later, so the click or key that opened the field has finished and doesn't take the focus back.
	local function focusLater()
		task.defer(function()
			if ref and Vide.untrack(props.isOpen) then
				ref.focus()
			end
		end)
	end

	Vide.effect(function()
		if props.isOpen() then
			focusLater()
		elseif ref and ref.getIsFocused() then
			ref.releaseFocus()
		end
	end)

	local function submit()
		local value = Vide.untrack(text)
		if value == "" then
			return
		end
		text("")
		props.close()
		input.onSubmit(value)
	end

	return VideFoundation.TextInput({
		text = text,
		onChanged = function(value: string)
			text(value)
		end,
		label = "",
		size = props.size,
		width = props.width,
		placeholder = function()
			return placeholderOf(props.icon)
		end,
		onReturnPressed = submit,
		textBoxRef = function(handle: VideFoundation.TextInputRef)
			ref = handle
			focusLater()
		end,
	})
end

return {
	InputFieldView = InputFieldView,
	widthOf = widthOf,
}
