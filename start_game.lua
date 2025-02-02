local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- incoming from client
local queue_event = ReplicatedStorage.QueueEvent
local exit_event = ReplicatedStorage.ExitEvent

-- outgoing to client
local match_found_event = ReplicatedStorage.MatchFoundEvent
local opponent_left_event = ReplicatedStorage.OpponentLeftEvent

local player_queue = {}

local rack = workspace.my_connect_4

local rack_position = rack.WorldPivot.Position

local rack_height = 9.14

local location_list = {-1,0,1,2}

local rack_width = rack.Union.Size.Z

function alert(player, text)
	local alert = player.PlayerGui.ScreenGui.alert:Clone()
	alert.Parent = player.PlayerGui.ScreenGui
	alert.Visible = true
	Debris:AddItem(alert,5)

	alert.Text = text
end


function start_game(player_1, player_2)
	if not (player_1 and player_2) then
		--print("error")
		return
	end
	
	local rack = workspace:FindFirstChild("my_connect_4"):Clone()
	rack.Parent = workspace
	
	local location_num = table.remove(location_list, math.random(1,#location_list))
	--print(location_num)
	local location = Vector3.new(location_num*1.5*rack_width, rack_height, rack_position.Z)
	
	rack:MoveTo(location)
	
	rack:SetAttribute("game", true)
	rack:SetAttribute("turn", 1)
	rack:SetAttribute("team_1", player_1.Name)
	
	-- use for exit button to delete rack from list
	rack:SetAttribute("location", location_num)
	
	
	
	player_1:SetAttribute("color", Color3.fromRGB(255, 0, 4))
	
	player_1.Character:MoveTo(Vector3.new(location.X, 3, location.Z + 5))
	
	--player_1.PlayerGui.ScreenGui.exit.Visible = true
	match_found_event:FireClient(player_1)
	
	--player_1.Character.RootHumanoidPart.Position = 
	
	if typeof(player_2) == "number" then
		rack:SetAttribute("team_2", "ai")
		rack:SetAttribute("ai", player_2)
	else
		rack:SetAttribute("team_2", player_2.Name)
		--player_2.Character.RootHumanoidPart.Position = 
		player_2.Character:MoveTo(Vector3.new(location.X, 3, location.Z - 5))
		
		--player_2.PlayerGui.ScreenGui.exit.Visible = true
		match_found_event:FireClient(player_2)
	end
	
	
end

queue_event.OnServerEvent:Connect(function(player, ai)
	--print("start")
	--print(ai)
	
	-- player wants to play vs ai
	if ai then
		--print("ai")
		-- start game with player vs ai
		
		-- remove player from table if they are in it
		if player_queue[1] == player then
			table.remove(player_queue, 1)
		end
		
		start_game(player, ai)
		return
	end
	
	if #player_queue == 1 then
		start_game(table.remove(player_queue, 1), player)
		
		-- start player with player 1 and player 2
	else
		table.insert(player_queue, player)
	end
end)



local left_text = "Your opponent has left the experience!"
local match_text = "Your opponent has quit the match!"

function end_game(player_name, left_game)
	--print("Entered")
	for _, child in ipairs(workspace:GetChildren()) do
		
		--print(child)
		-- child is connect 4 rack
		local location = child:GetAttribute("location")
		-- if connect 4 rack has player
		local player_1 = child:GetAttribute("team_1")
		local player_2 = child:GetAttribute("team_2")
		
		--print(player_1, player_2)

		if player_name == player_1 or player_name == player_2 then
			--print("true")
			table.insert(location_list, location)
			
			--print(location_list)

			child:Destroy()
			
			if player_1 == "ai" or player_2 == "ai" then
				return
			end
			
			local opponent
			
			if player_name == player_1 then
				-- if two players need to reset GUI
				opponent = Players:FindFirstChild(player_2)
				
			else --if player_name == player_2 then
				opponent = Players:FindFirstChild(player_1)
			end
			
			if opponent then
				local text
				if left_game then
					text = left_text
				else
					text = match_text
				end
				alert(opponent, text)
				print("test")
				opponent_left_event:FireClient(opponent)
			end
		end
	end
end

-- remove player from queue if they disconnect
Players.PlayerRemoving:Connect(function(player)
	local index = table.find(player_queue, player)
	
	if index then
		table.remove(player_queue, index)
	end
	
	-- check if player was in game and it needs to end
	local left_game = true
	end_game(player.Name, left_game)
end)

exit_event.OnServerEvent:Connect(function(player)
	-- TODO: fix this scheme of exit -> play
	--player.PlayerGui.ScreenGui.exit.Visible = false
	--print("true")
	local didnt_leave_game = false
	end_game(player.Name, didnt_leave_game)
end)