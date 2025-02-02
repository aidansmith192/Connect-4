local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- outgoing to client
local selection_event = ReplicatedStorage.SelectionEvent

-- outgoing to server
local turn_event = ServerStorage.TurnEvent

-- incoming from server
local ai_drop_event = ServerStorage.AIDropEvent

local rack = script.Parent.Parent

local Players = game:GetService("Players")

function is_game()
	if rack:GetAttribute("game") then
		--print("game")
		return true
	end
end

function is_invalid_player(child, player)	
	if not is_game() then
		--print("no game")
		return true
	end
	
	if rack:GetAttribute("team_" .. rack:GetAttribute("turn")) ~= player.Name or child:GetAttribute("row") > 6 then
		--print("bad player")
		return true
	end
	
	return false
end

function reset_highlight()
	for _, child in ipairs(script.Parent:GetChildren()) do
		if child.ClassName ~= "Part" then
			continue
		end
		
		child.ClickDetector.MaxActivationDistance = 0
	end
	
	task.wait(0.05)
	
	for _, child in ipairs(script.Parent:GetChildren()) do
		if child.ClassName ~= "Part" then
			continue
		end
		--print("done")
		
		child.ClickDetector.MaxActivationDistance = 32
	end
end

function drop_coin(child, player)
	-- up count
	local cur_row = child:GetAttribute("row")
	child:SetAttribute("row", child:GetAttribute("row") + 1)


	-- swap turns
	local TEAM_SWAP = {2,1}
	local team = rack:GetAttribute("turn")
	rack:SetAttribute("turn", 0) -- to allow for 1 second delay for moves
	
	
	--print(rack:GetAttribute("turn"), rack:GetAttribute("team_" .. rack:GetAttribute("turn")))

	--print(team, rack:GetAttribute("turn"))

	-- stop hover
	if player ~= "ai" then
		selection_event:FireClient(player, child, false)
	end

	-- drop chip
	local coin = child.coin:Clone()
	coin.Parent = child
	coin.coin.CanCollide = true
	coin.Name = "coin" .. cur_row
	coin:SetAttribute("team", team)

	local coin_color
	if team == 1 then
		coin_color = Color3.fromRGB(255,0,0)
	else
		coin_color = Color3.fromRGB(255,255,0)
	end

	for _, coin_part in ipairs(coin:GetChildren()) do
		coin_part.Color = coin_color
		coin_part.Transparency = 0
		coin_part.Anchored = false
	end

	-- check for next player. *is it another player or AI?*
	-- probably make call to script to check if game is won, then pass turn to next player
	turn_event:Fire(script.Parent.Parent)


	-- move coin to correct position after it has a second to fall
	task.wait(1)

	rack:SetAttribute("turn", TEAM_SWAP[team])
	
	reset_highlight()
	
	-- coin position
	local bottom_column = child.Position.Y - child.Size.Y/2
	local coin_diameter = coin.coin.Size.Y
	local coin_radius   = coin_diameter/2
	local coin_offset   = coin_diameter * (cur_row - 1)
	local new_height    = bottom_column + coin_radius + coin_offset


	-- coin rotation
	local x_rot = coin.coin.Orientation.X
	local y_rot = coin.coin.Orientation.Y

	-- 90 degree mid point will affect X rotation, need to have correct sign
	if math.rad(y_rot) >= 0 then
		y_rot = 90
	else
		y_rot = -90
	end

	local rot = CFrame.fromEulerAnglesYXZ(math.rad(x_rot), math.rad(y_rot), 0)
	local pos = CFrame.new(child.Position.X, new_height, child.Position.Z)

	coin:PivotTo(pos * rot)

	for _, coin_part in ipairs(coin:GetChildren()) do
		coin_part.Anchored = true
	end
end

for _, child in ipairs(script.Parent:GetChildren()) do
	if child.ClassName ~= "Part" then
		continue
	end
	
	child:SetAttribute("row", 1)

	child.ClickDetector.MouseHoverEnter:Connect(function(player)
		--print("entered")
		if is_invalid_player(child, player)	then
			--print("invalid")
			
			return
		end
		
		selection_event:FireClient(player, child, true)
	end)
	child.ClickDetector.MouseHoverLeave:Connect(function(player)
		if is_invalid_player(child, player)	then
			return
		end	
		
		selection_event:FireClient(player, child, false)
	end)
	
	child.ClickDetector.MouseClick:Connect(function(player)		
		if is_invalid_player(child, player)	then
			return
		end
		
		drop_coin(child, player)
	end)
end

ai_drop_event.Event:Connect(function(specfic_rack, specific_column)
	if rack ~= specfic_rack then
		return
	end
	
	local column = rack.column_selector:FindFirstChild("column" .. specific_column)
	if column then
		drop_coin(column, "ai")
	end
end)