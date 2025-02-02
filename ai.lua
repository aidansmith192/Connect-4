local ServerStorage = game:GetService("ServerStorage")

-- outgoing to server
local ai_drop_event = ServerStorage.AIDropEvent

-- incoming from server
local ai_turn_event = ServerStorage.AITurnEvent

local NUM_ROWS, NUM_COLUMNS = 6, 7

local INFINITY = tonumber("inf")

function clone_stack(old_stack)
	local stack = {}
	for i = 1, NUM_ROWS, 1 do
		table.insert(stack, {})
		for j = 1, NUM_COLUMNS, 1 do
			local val = 0
			if old_stack[i][j] == 1 then
				val = 1
			elseif old_stack[i][j] == 2 then
				val = 2
			end
			table.insert(stack[i], val)
		end
	end
	return stack
end

function determine_count(quad, team_num)
	local count = 0
	local empty = 0
	for _, coin in ipairs(quad) do
		if coin == team_num then
			count += 1
		elseif coin == 0 then
			empty += 1
		end
	end
	return count, empty
end

function score_count(count, empty)
	if count == 4 then
		return 100
	elseif count == 3 and empty == 1 then
		return 5
	elseif count == 2 and empty == 2 then
		return 2
	elseif count == 1 and empty == 3 then
		return 1
	elseif count == 0 and empty == 3 then
		return 0
	elseif count == 0 and empty == 2 then
		return -1
	elseif count == 0 and empty == 1 then
		return -4
	elseif count == 0 and empty == 0 then
		return -100
	else
		return 0
	end
end

function value(stack, team_num)
	-- convert rack to table
	
	--print(stack)
	
	local score = 0

	-- check horizontal
	for i = 1, NUM_ROWS, 1 do

		for j = 1, NUM_COLUMNS - 3, 1 do
			local quad = {}
			table.move(stack[i], j, j+3, 1, quad)
			
			local count, empty = determine_count(quad, team_num)
			
			score += score_count(count, empty)
		end
	end

	-- check vertical
	for i = 1, NUM_COLUMNS, 1 do
		for j = 1, NUM_ROWS - 3, 1 do
			local quad = {}
			for l = 0, 3, 1 do
				--quad = stack[j + l][i]
				table.insert(quad, stack[j + l][i])
			end

			local count, empty = determine_count(quad, team_num)

			score += score_count(count, empty)
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
			for l = 1, diag_length_array[j] - 3, 1 do
				local quad = {}
				for k = 0, 3, 1 do
					local row = diag_start_index[i][j][1] + (l-1) + k
					local column = diag_start_index[i][j][2] + diag_dir[i] * ((l-1) + k)
					--quad = stack[row][column]
					table.insert(quad, stack[row][column])
				end

				local count, empty = determine_count(quad, team_num)

				score += score_count(count, empty)
			end
		end
	end
	
	--print("eval", score)
	return score
end

function is_winner(stack)
	-- convert rack to table

	--print(stack)

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

local COLUMN_LIST = {1, 2, 3, 4, 5, 6, 7}

function minimax(stack, depth, team_num, max_player, alpha, beta)
	--print("depth", depth)
	--print(stack)
	local winner = is_winner(stack)
	--print(stack)
	if winner then
		--print(winner)
		--print("winner", winner, "team_num", team_num)
		if winner == team_num then
			return nil, 1000000000
		else
			return nil, -100000000
		end
	end
	
	if depth == 0 then
		--print("value function called")
		return nil, value(stack, team_num)
		--if not max_player then
		--	return nil, value(stack, team_num)
		--else
			
		--end
	end

	local col_list = table.clone(COLUMN_LIST)
	local rand_order = {}
	for i = NUM_COLUMNS, 1, -1 do
		table.insert(rand_order, table.remove(col_list, math.random(1,i)))
	end
	
	local column = rand_order[1]
	
	if max_player then
		local value = -1 * INFINITY
		--print(value)
		
		
		--print(rand_order)
		
		for rand_index = 1, NUM_COLUMNS, 1 do
			
			local col = rand_order[rand_index]
			--print(col)
			
			--print("ai loop", col, "depth", depth)
			-- if you can place a piece
			if stack[NUM_ROWS][col] ~= 0 then
				--print("skip")
				continue
			end
			
			local new_stack = clone_stack(stack)
			
			for i = 1, NUM_ROWS, 1 do
				if new_stack[i][col] == 0 then
					new_stack[i][col] = team_num
					break
				end
			end
			
			--local opposite_team_num = 1
			--if team_num == 1 then
			--	opposite_team_num = 2
			--end

			local _, new_score = minimax(new_stack, depth - 1, team_num, not max_player, alpha, beta)
			
			if new_score > value then
				--print("ai max: ", new_score)
				value = new_score
				column = col
			end
			
			alpha = math.max(alpha, value)
			--print("alpha", alpha, "beta", beta)
			if alpha >= beta then
				--print("break")
				--break
			end
		end
		
		if value == -1 * INFINITY then
			return column, 0
		end
		
		--print("ai", column, "c/v", value, "depth", depth)

		return column, value
		
	else -- minimizing player
		local value = INFINITY
		
		for rand_index = 1, NUM_COLUMNS, 1 do

			local col = rand_order[rand_index]
			--print("opp col", col)
			
			-- if you can place a piece
			if stack[NUM_ROWS][col] ~= 0 then
				continue
			end
			
			local opposite_team_num = 1
			if team_num == 1 then
				opposite_team_num = 2
			end

			local new_stack = clone_stack(stack)

			for i = 1, NUM_ROWS, 1 do
				if new_stack[i][col] == 0 then
					new_stack[i][col] = opposite_team_num
					break
				end
			end

			local _, new_score = minimax(new_stack, depth - 1, team_num, not max_player, alpha, beta)

			if new_score < value then
				--print("player max: ", new_score)
				value = new_score
				column = col
			end
			--print("opp value", value)
			
			--print("alpha", alpha, "beta", beta)
			beta = math.min(beta, value)
			--print("alpha", alpha, "beta", beta)
			if alpha >= beta then
				--print("break")
				--break
			end
		end
		
		--print("opp", value)
		
		if value == INFINITY then
			return column, 0
		end
		
		--print("player", column, "c/v", value, "depth", depth)
		
		return column, value
	end
	

end

function start_minimax(rack, depth, team_num)
	if depth == 0 then
		--print("depth", depth)
		
		local open_col = table.clone(COLUMN_LIST)
		
		for col = NUM_COLUMNS, 1, -1 do
			-- if you can place a piece
			if rack.column_selector:FindFirstChild("column" .. col):FindFirstChild("coin" .. 6) then
				table.remove(open_col, col)
			end
		end
		
		local index =  math.random(1,#open_col)
			
		ai_drop_event:Fire(rack, open_col[index])
		return
	end
	
	
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
	
	local maximizing_player = true
	local alpha = -1 * INFINITY
	--print("alpha", alpha)
	local beta = INFINITY
	
	local column, _ = minimax(stack, depth, team_num, maximizing_player, alpha, beta)
	
	ai_drop_event:Fire(rack, column)
end

ai_turn_event.Event:Connect(function(rack, depth, team_num)
	start_minimax(rack, depth, team_num)
end)