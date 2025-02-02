local ServerStorage = game:GetService("ServerStorage")

-- incoming from server
local turn_event = ServerStorage.TurnEvent

-- outgoing to server
local drop_all_event = ServerStorage.DropAllEvent
local ai_turn_event = ServerStorage.AITurnEvent

local NUM_ROWS, NUM_COLUMNS = 6, 7

local Players = game:GetService("Players")

local Debris = game:GetService("Debris")

local winner_highlight = workspace:WaitForChild("winner")

local WIN_TIMER = 5

function highlight_winner(coin_1, coin_4, team, rot, replacement_y, diag)
	--task.wait(1)
	local team_color
	if team == 1 then
		team_color = Color3.fromRGB(255,0,0)
	else
		team_color = Color3.fromRGB(255,255,0)
	end
	
	local winner = winner_highlight:Clone()

	winner.Parent = workspace	
	
	local pos_x = (coin_1.coin.Position.X + coin_4.coin.Position.X) / 2
	local pos_y = (coin_1.coin.Position.Y + coin_4.coin.Position.Y) / 2
	local pos_z = (coin_1.coin.Position.Z + coin_4.coin.Position.Z) / 2
	
	local coin_spawn_height = coin_1.Parent.coin.coin.Position.Y
	
	-- as coin drops, it will have wrong Y
	if coin_1.coin.Position.Y == coin_spawn_height then
		pos_y = (coin_4.coin.Position.Y + replacement_y) / 2
	elseif coin_4.coin.Position.Y == coin_spawn_height then
		pos_y = (coin_1.coin.Position.Y + replacement_y) / 2
	end
	
	--print(pos_x, pos_y)
	
	winner.Position = Vector3.new(pos_x, pos_y, pos_z)
	winner.Orientation = rot
	
	local size_x = math.abs(coin_1.coin.Position.X - coin_4.coin.Position.X) + 2
	local size_y = math.abs(coin_1.coin.Position.Y - coin_4.coin.Position.Y) + 2
	local size_z = winner.Size.Z
	

	
	-- as coin drops, it will have wrong Y
	if coin_1.coin.Position.Y == coin_spawn_height then
		size_y = math.abs(coin_4.coin.Position.Y - replacement_y) + 2
	elseif coin_4.coin.Position.Y == coin_spawn_height then
		size_y = math.abs(coin_1.coin.Position.Y - replacement_y) + 2
	end
	
	-- if diag then leave y and extend X
	if diag then
		size_y = 2
		size_x += 2
	end
	
	winner.Size = Vector3.new(size_x, size_y, size_z)
	
	winner.SelectionBox.Color3 = team_color

	Debris:AddItem(winner, WIN_TIMER)
end

-- check if board is full
function is_tie(stack)
	for i = 1, NUM_ROWS, 1 do
		for j = 1, NUM_COLUMNS, 1 do
			if stack[i][j] == 0 then
				return false
			end
		end
	end
	return true
end

function is_winner(rack)
	-- convert rack to table
	local stack = {}
	for i = 1, NUM_ROWS, 1 do
		table.insert(stack, {})
	end
	
	local columns = rack.column_selector
	
	for i = 1, NUM_COLUMNS, 1 do
		local column = columns:FindFirstChild("column" .. i)
		--print(column)
		for j = 1, NUM_ROWS, 1 do
			local coin = column:FindFirstChild("coin" .. j)
			--print(coin)
			if coin then
				--print(coin)
				local coin_team = coin:GetAttribute("team")
				table.insert(stack[j], coin_team)
			else
				table.insert(stack[j], 0)
			end
		end
	end
	
	-- check if board is full
	if is_tie(stack) then
		return 0
	end
	
	-- check horizontal
	for i = 1, NUM_ROWS, 1 do
		local in_a_row = 0
		local team = 0
		
		for j = 1, NUM_COLUMNS, 1 do
			if stack[i][j] == 0 then
				in_a_row = 0
				team = 0
			elseif stack[i][j] == team then
				in_a_row += 1
				if in_a_row == 4 then
					--declare_winner(team)
					--print("winner")
					
					local coin_1 = rack.column_selector:FindFirstChild("column" .. j-3):FindFirstChild("coin"..i)
					local coin_4 = rack.column_selector:FindFirstChild("column" .. j):FindFirstChild("coin"..i)
					
					--print(coin_1.coin.Position.Y, coin_4.coin.Position.Y)
					
					local coin_spawn_height = coin_1.Parent.coin.coin.Position.Y
					
					local replacement_y = 0
					-- as coin drops, it will have wrong Y
					if coin_1.coin.Position.Y == coin_spawn_height then
						replacement_y = coin_4.coin.Position.Y
					elseif coin_4.coin.Position.Y == coin_spawn_height then
						replacement_y = coin_1.coin.Position.Y
					end
					
					local rot = Vector3.new(0,0,0)
					
					highlight_winner(coin_1, coin_4, team, rot, replacement_y)
					
					return team
				end
			else
				in_a_row = 1
				team = stack[i][j]
			end
		end
	end
	
	-- check vertical
	for i = 1, NUM_COLUMNS, 1 do
		local in_a_row = 0
		local team = 0
		
		for j = 1, NUM_ROWS, 1 do
			if stack[j][i] == 0 then
				in_a_row = 0
				team = 0
			elseif stack[j][i] == team then
				in_a_row += 1
				if in_a_row == 4 then
					--declare_winner(team)
					--print("winner")
					
					local coin_1 = rack.column_selector:FindFirstChild("column" .. i):FindFirstChild("coin"..j-3)
					local coin_4 = rack.column_selector:FindFirstChild("column" .. i):FindFirstChild("coin"..j)
					
					-- as coin drops, it will have wrong Y
					local replacement_y = coin_1.coin.Position.Y + coin_1.coin.Size.Y * 3
					
					local rot = Vector3.new(0,0,0)

					highlight_winner(coin_1, coin_4, team, rot, replacement_y)
					
					return team
				end
			else
				in_a_row = 1
				team = stack[j][i]
			end
		end
	end
	
	-- check diagonal
	local diag_directions = 2
	local diag_checks = 6

	local diag_dir = {1, -1}
	local diag_length_array = {4, 5, 6, 6, 5, 4}
	local diag_start_index = {
		{{3,1}, {2,1}, {1,1}, {1,2}, {1,3}, {1,4}},
		{{1,4}, {1,5}, {1,6}, {1,7}, {2,7}, {3,7}}
		
	}
	
	for i = 1, diag_directions, 1 do
		for j = 1, diag_checks, 1 do
			local in_a_row = 0
			local team = 0
			
			for l = 1, diag_length_array[j], 1 do
				local row = diag_start_index[i][j][1] + (l-1)
				local column = diag_start_index[i][j][2] + diag_dir[i] * (l-1)
				
				--print(row, column)
				
				if stack[row][column] == 0 then
					in_a_row = 0
					team = 0
				elseif stack[row][column] == team then
					in_a_row += 1
					if in_a_row == 4 then
						--declare_winner(team)
						--print("winner")
						
						local coin_1 = rack.column_selector:FindFirstChild("column" .. column - (3 * diag_dir[i])):FindFirstChild("coin"..row - 3)
						local coin_4 = rack.column_selector:FindFirstChild("column" .. column):FindFirstChild("coin"..row)
						
						local coin_spawn_height = coin_1.Parent.coin.coin.Position.Y
						
						local replacement_y = 0
						-- as coin drops, it will have wrong Y
						if coin_1.coin.Position.Y == coin_spawn_height then
							replacement_y = coin_4.coin.Position.Y - coin_4.coin.Size.Y * 3
						elseif coin_4.coin.Position.Y == coin_spawn_height then
							replacement_y = coin_1.coin.Position.Y + coin_1.coin.Size.Y * 3
						end
						
						local rot = Vector3.new(0,0,45 * diag_dir[i])
						
						local diag = true

						highlight_winner(coin_1, coin_4, team, rot, replacement_y, diag)
						
						return team
					end
				else
					in_a_row = 1
					team = stack[row][column]
				end
			end
		end
	end
	
	return false
end

function end_turn(rack)
	-- check if game over
	local winner = is_winner(rack)
	if winner then
		rack:SetAttribute("game", false)
		
		-- make draw clickable
		drop_all_event:Fire(rack)
		
		if winner == 0 then
			-- tie
		end
		
		task.wait(WIN_TIMER + 0.1)
		
		rack:SetAttribute("game", true)
		
		rack:SetAttribute("turn", 1)
		
		-- swap teams
		local old_player_1 = rack:GetAttribute("team_1")
		local old_player_2 = rack:GetAttribute("team_2")
		rack:SetAttribute("team_1", old_player_2)
		rack:SetAttribute("team_2", old_player_1)
		
		if old_player_2 == "ai" then
			--print("entered")
			local depth = rack:GetAttribute("ai")
			--print("fired")
			ai_turn_event:Fire(rack, depth, 1)
		end
		
	-- if not, pass to next player or AI	
	else
		
		task.wait(1)
		
		
		
		--print(depth)
		
		local team = rack:GetAttribute("turn")
		if rack:GetAttribute("team_" .. team) == "ai" then
			--print("entered")
			local depth = rack:GetAttribute("ai")
			--print("fired")
			ai_turn_event:Fire(rack, depth, team)
			--task.wait(1)
		end
		
	end
end

turn_event.Event:Connect(function(rack)
	end_turn(rack)
end)