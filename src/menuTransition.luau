local Vide = require("./Packages/Vide")
local VideRipple = require("./Packages/VideRipple")

--* Unibar's MENU_ANIMATION_SPRING (Chrome/ChromeShared/Unibar/Constants.lua), which opens its ⋯ menu and turns the
--* icon into an x.
local SPRING: VideRipple.SpringOptions<number> = { dampingRatio = 1.1, frequency = 1 / 0.15 }
--* Roblox draws its ⋯ menu a frame after the click and steps it at 60 Hz, so its first visible frame is already a
--* step into the spring: 65% open, 58% closed (measured). Skipping one such step at every turn shows the same first
--* frame at any frame rate, without the lag. Ripple's overdamped spring is Otter's formula, so the curve is the same.
local SKIP = 1 / 60

--- A value going from 0 to 1 as `isOpen` turns on and back as it turns off, the way Roblox's ⋯ menu moves.
local function useMenuTransition(isOpen: () -> boolean): (() -> number, VideRipple.Spring<number>)
	local transition, spring = VideRipple.useSpring(0, SPRING)
	local wasOpen = false

	--! Vide's strict mode runs effects twice; without the guard the second run would skip twice as far.
	Vide.effect(function()
		local open = isOpen()
		if open ~= wasOpen then
			wasOpen = open
			spring:setGoal(if open then 1 else 0)
			spring:step(SKIP)
		end
	end)

	return transition, spring
end

return useMenuTransition
