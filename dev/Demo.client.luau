--* Every VideTopbar feature on the live topbar, to try in Play.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local VideTopbar = require(ReplicatedStorage.Packages.VideTopbar)

local images = {
	example = Content.fromAssetId(16086868244),
	exampleSelected = Content.fromAssetId(16086868447),
	mute = Content.fromAssetId(7248002480),
	unmute = Content.fromAssetId(7248002631),
}

local function withCommas(value: number): string
	local text = tostring(math.floor(value))
	local count
	repeat
		text, count = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return text
end

VideTopbar.mount()

local exampleSelected = Vide.source(false)
local menuNotices = Vide.source(1)
local inventoryNotices = Vide.source(0)
local capturing = Vide.source(false)
local leaderboardOpen = Vide.source(false)
local inventoryOpen = Vide.source(false)
local shopOpen = Vide.source(false)
local shopSeen = Vide.source(false)
local muted = Vide.source(false)
local plusNotices = Vide.source(if Players.LocalPlayer.HasRobloxSubscription then 0 else 1)
local points = Vide.source(math.random(1, 1000))
local fillers = Vide.source(0)
local profileOpen = Vide.source(false)
local vipDisabled = Vide.source(true)
local liked = Vide.source(false)

local function say(text: string): () -> ()
	return function()
		print(`[Demo] {text}`)
	end
end

--* `leading` content: the player's headshot with a status dot.
local function Avatar(isActive: () -> boolean): GuiObject
	local player = Players.LocalPlayer
	local holder = Instance.new("Frame")
	holder.Name = "Avatar"
	holder.Size = UDim2.fromOffset(28, 28)
	holder.BackgroundTransparency = 1

	local headshot = Instance.new("ImageLabel")
	headshot.Size = UDim2.fromScale(1, 1)
	headshot.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	headshot.ImageContent = Content.fromUri(`rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`)
	local headshotCorner = Instance.new("UICorner")
	headshotCorner.CornerRadius = UDim.new(1, 0)
	headshotCorner.Parent = headshot
	headshot.Parent = holder

	local status = Instance.new("Frame")
	status.AnchorPoint = Vector2.new(1, 1)
	status.Position = UDim2.fromScale(1, 1)
	status.Size = UDim2.fromOffset(9, 9)
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(1, 0)
	statusCorner.Parent = status
	local statusStroke = Instance.new("UIStroke")
	statusStroke.Color = Color3.fromRGB(30, 30, 35)
	statusStroke.Thickness = 1.5
	statusStroke.Parent = status
	status.Parent = holder

	Vide.effect(function()
		status.BackgroundColor3 = if isActive() then Color3.fromRGB(70, 210, 110) else Color3.fromRGB(150, 150, 150)
	end)
	return holder
end

Vide.root(function()
	VideTopbar.Icon({
		order = 1,
		label = "Example",
		image = function()
			return if exampleSelected() then images.exampleSelected else images.example
		end,
		selected = exampleSelected,
		autoDeselect = true,
	})
	VideTopbar.Icon({
		order = 3,
		label = Players.LocalPlayer.DisplayName,
		leading = function()
			return Avatar(profileOpen)
		end,
		tooltip = "Your profile",
		--* Only shown: P is handled by the demo itself, at the bottom.
		shortcutHint = Enum.KeyCode.P,
		selected = profileOpen,
	})
	VideTopbar.Icon({
		order = 2,
		label = "Menu",
		--* The Inventory row's badge is added on top of this one by VideTopbar.
		badge = menuNotices,
		tooltip = "Example Menu",
		shortcut = Enum.KeyCode.M,
		onActivated = function()
			menuNotices(0)
		end,
		--* The rows wear the glyphs of Roblox's own ⋯ menu (its integrations' CommonIcon off/on pairs, which Builder
		--* Icons' migration maps to one glyph and its Filled variant), filled while what they open is open.
		menu = function()
			VideTopbar.Icon({ order = 1, icon = "photo-camera", label = "Captures", selected = capturing })
			VideTopbar.Icon({ order = 2, icon = "trophy", label = "Leaderboard", selected = leaderboardOpen })
			--* A row with a list of its own, which opens in place of this one.
			VideTopbar.Icon({
				order = 3,
				icon = "square-face-waving-hand",
				label = "Emotes",
				menu = function()
					for index, name in { "Wave", "Cheer", "Dance" } do
						VideTopbar.Icon({ order = index, label = name, onActivated = say(name) })
					end
				end,
			})
			VideTopbar.Icon({
				order = 4,
				icon = "backpack",
				label = "Inventory",
				badge = inventoryNotices,
				selected = inventoryOpen,
				onActivated = function()
					inventoryNotices(0)
				end,
			})
			VideTopbar.Icon({
				order = 5,
				icon = "person-standing-arrow-reverse",
				label = "Respawn",
				onActivated = say("respawn"),
			})
			VideTopbar.Icon({
				order = 6,
				icon = "shopping-cart",
				label = "Shop",
				--* A text badge until the shop is first opened.
				badge = function()
					return if shopSeen() then nil else "NEW"
				end,
				selected = shopOpen,
				shortcut = { Enum.KeyCode.LeftControl, Enum.KeyCode.B },
				onActivated = function()
					shopSeen(true)
				end,
			})
		end,
	})
	--* VIP starts disabled, dimmed and deaf to V, until More's first row enables it.
	VideTopbar.Icon({
		order = 4,
		icon = "crown",
		label = "VIP",
		tooltip = "VIP lounge",
		shortcut = Enum.KeyCode.V,
		isDisabled = vipDisabled,
		onActivated = say("vip"),
	})
	--* A row menu: its icons slide out of the star, which turns into an x.
	VideTopbar.Icon({
		order = 5,
		icon = "star",
		tooltip = "Favourites",
		menuStyle = "Row",
		menu = function()
			VideTopbar.Icon({ order = 1, icon = "heart", tooltip = "Like", selected = liked })
			VideTopbar.Icon({ order = 2, icon = "trophy", tooltip = "Badges", onActivated = say("badges") })
			VideTopbar.Divider({ order = 3 })
			VideTopbar.Icon({
				order = 4,
				icon = "crown",
				tooltip = "Leaders",
				menu = function()
					VideTopbar.Icon({ order = 1, label = "Today", onActivated = say("today") })
					VideTopbar.Icon({ order = 2, label = "All time", onActivated = say("all time") })
				end,
			})
		end,
	})

	VideTopbar.Group({ side = "Right", order = 1 }, function()
		VideTopbar.Icon({
			order = 1,
			image = function()
				return if muted() then images.unmute else images.mute
			end,
			tooltip = function()
				return if muted() then "Unmute" else "Mute"
			end,
			shortcut = { Enum.KeyCode.LeftControl, Enum.KeyCode.N },
			selected = muted,
		})
		VideTopbar.Divider({ order = 2 })
		VideTopbar.Icon({
			order = 3,
			icon = "roblox-plus",
			badge = plusNotices,
			tooltip = "Get Roblox Plus",
			onActivated = function()
				plusNotices(0)
				MarketplaceService:PromptRobloxSubscriptionPurchase(Players.LocalPlayer)
			end,
		})
		--* A menu behind Roblox's own hamburger glyph, which turns into an x while open.
		VideTopbar.Icon({
			order = 4,
			icon = "three-bars-horizontal",
			tooltip = "More",
			menu = function()
				VideTopbar.Icon({
					order = 0,
					icon = "crown",
					label = function()
						return if vipDisabled() then "Enable VIP" else "Disable VIP"
					end,
					onActivated = function()
						vipDisabled(not vipDisabled())
					end,
				})
				VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings", onActivated = say("settings") })
				VideTopbar.Icon({
					order = 2,
					icon = "bell",
					label = "Notifications",
					badge = true,
					onActivated = say("notifications"),
				})
				--* Disabled along with VIP, to show a dimmed row; its shortcut R does nothing until then.
				VideTopbar.Icon({
					order = 3,
					icon = "flag",
					label = "Report",
					shortcut = Enum.KeyCode.R,
					isDisabled = vipDisabled,
					onActivated = say("report"),
				})
			end,
		})
	end)
	VideTopbar.Icon({
		side = "Right",
		order = 2,
		label = "Testttttttt",
		shortcut = Enum.KeyCode.T,
		tooltip = "Hello this is a test caption",
		menu = function()
			for index, name in { "AAA", "BBB", "CCC", "DDD" } do
				VideTopbar.Icon({ order = index, label = name, onActivated = say(name) })
			end
		end,
	})
	VideTopbar.Icon({
		side = "Right",
		order = 3,
		label = function()
			return `${withCommas(points())}`
		end,
		minWidth = 80,
	})

	--* = adds a filler icon, alternating sides, and - removes one, to crowd the bar until its overflow menus appear.
	local fillerList = Vide.derive(function()
		local list = {}
		for index = 1, fillers() do
			list[index] = index
		end
		return list
	end)
	Vide.indexes(fillerList, function(_, index: number)
		local isLeft = index % 2 == 1
		VideTopbar.Icon({
			side = if isLeft then "Left" else "Right",
			order = if isLeft then 10 + index else -index,
			icon = "gear",
			label = `Filler {index}`,
			badge = if index % 3 == 0 then index else nil,
			onActivated = say(`filler {index}`),
			--* Some fillers have a menu, to try one from inside an overflow menu.
			menu = if index % 4 == 1
				then function()
					VideTopbar.Icon({ order = 1, icon = "gear", label = `Filler {index} A`, onActivated = say("A") })
					VideTopbar.Icon({ order = 2, icon = "bell", label = `Filler {index} B`, onActivated = say("B") })
				end
				else nil,
		})
		return nil
	end)

	Vide.effect(function()
		print("[Demo] shop open:", shopOpen())
	end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Equals then
		fillers(fillers() + 1)
	elseif input.KeyCode == Enum.KeyCode.P then
		profileOpen(not profileOpen())
	elseif input.KeyCode == Enum.KeyCode.Minus then
		fillers(math.max(0, fillers() - 1))
	end
end)

task.delay(10, function()
	inventoryNotices(1)
end)

task.spawn(function()
	while true do
		task.wait(1)
		points(math.random(1, 1000))
	end
end)
