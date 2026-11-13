--* TopbarPlus's playground demo (StarterGui.TestGUIs.EXAMPLES in its place) rebuilt with VideTopbar. Its sideways
--* menu and dropdowns are Roblox-style menus here, and Mute and Premium share a group.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vide = require(ReplicatedStorage.Packages.Vide)
local VideTopbar = require(ReplicatedStorage.Packages.VideTopbar)

--* The image ids the TopbarPlus demo uses.
local images = {
	example = Content.fromAssetId(16086868244),
	exampleSelected = Content.fromAssetId(16086868447),
	captures = Content.fromAssetId(132131908946422),
	leaderboard = Content.fromAssetId(77963268913241),
	emotes = Content.fromAssetId(85873312676193),
	inventory = Content.fromAssetId(88192794455898),
	respawn = Content.fromAssetId(79448871490237),
	shop = Content.fromAssetId(4882429582),
	mute = Content.fromAssetId(7248002480),
	unmute = Content.fromAssetId(7248002631),
	premium = Content.fromAssetId(6071020687),
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
local shopOpen = Vide.source(false)
local shopSeen = Vide.source(false)
local muted = Vide.source(false)
local premiumNotices = Vide.source(1)
local points = Vide.source(math.random(1, 1000))
local fillers = Vide.source(0)
local profileOpen = Vide.source(false)

local function say(text: string): () -> ()
	return function()
		print(`[Demo] {text}`)
	end
end

--* TopbarPlus's CustomInstance demo: the player's headshot with a status dot, added inside the icon.
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
		--* TopbarPlus's default: another icon selected unselects this one.
		autoDeselect = true,
	})
	VideTopbar.Icon({
		order = 3,
		label = Players.LocalPlayer.DisplayName,
		leading = function()
			return Avatar(profileOpen)
		end,
		tooltip = "Your profile",
		--* Only shown, like TopbarPlus's setCaptionHint: P is handled by the demo itself, at the bottom.
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
		menu = function()
			VideTopbar.Icon({ order = 1, image = images.captures, label = "Captures", onActivated = say("captures") })
			VideTopbar.Icon({
				order = 2,
				image = images.leaderboard,
				label = "Leaderboard",
				onActivated = say("leaderboard"),
			})
			VideTopbar.Icon({ order = 3, image = images.emotes, label = "Emotes", onActivated = say("emotes") })
			VideTopbar.Icon({
				order = 4,
				image = images.inventory,
				label = "Inventory",
				badge = inventoryNotices,
				onActivated = function()
					inventoryNotices(0)
				end,
			})
			VideTopbar.Icon({ order = 5, image = images.respawn, label = "Respawn", onActivated = say("respawn") })
			VideTopbar.Icon({
				order = 6,
				image = images.shop,
				label = "Shop",
				--* Not in the TopbarPlus demo: a text badge, like its setNoticeLabel, until the shop is first opened.
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
			image = images.premium,
			badge = premiumNotices,
			tooltip = "Buy Premium",
			onActivated = function()
				premiumNotices(0)
				MarketplaceService:PromptPremiumPurchase(Players.LocalPlayer)
			end,
		})
		--* Not in the TopbarPlus demo: a menu behind Roblox's own hamburger glyph, which turns into an x while open.
		VideTopbar.Icon({
			order = 4,
			icon = "three-bars-horizontal",
			tooltip = "More",
			menu = function()
				VideTopbar.Icon({ order = 1, icon = "gear", label = "Settings", onActivated = say("settings") })
				VideTopbar.Icon({
					order = 2,
					icon = "bell",
					label = "Notifications",
					badge = true,
					onActivated = say("notifications"),
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

	--* Not in the TopbarPlus demo: = adds a filler icon, alternating sides, and - removes one, to crowd the bar until
	--* its overflow menus appear.
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
