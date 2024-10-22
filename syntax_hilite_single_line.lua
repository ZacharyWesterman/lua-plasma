text = V1:gsub('\x0b', '\n')
cursor_pos = V2
cursor = V3

--BUILD COLOR SCHEME INFO
--access via e.g.: theme["keyword"].open <---> theme["keyword"].close
for key, value in pairs(theme) do
	local open = ""
	local close = ""
	if type(value[1]) ~= "table" then value = {value} end

	for _, i in pairs(value) do
		if #i > 1 then
			open = open .. "<"..i[1].."="..i[2]..">"
		else
			open = open .. "<"..i[1]..">"
		end
		close = close .. "</" .. i[1] .. ">"
	end

	theme[key] = {
		open = open,
		close = close,
	}
end

--TIDY UP SYNTAX PATTERNS
--This step makes patterns behave more nicely with lua's pattern matching
for key, value in pairs(patterns) do
	if value then
		if type(value.pattern) ~= "table" then
			value.pattern = {value.pattern}
		end
		for i, p in pairs(value.pattern) do
			value.pattern[i] = "^"..p
		end
		if value.lookahead ~= nil then value.lookahead = "^" .. value.lookahead end
	end
end

--returns scope_name, match_text
function check_scope(text, scope)
	local match
	for _, s in pairs(scope) do
		if patterns[s] then
			for _, p in pairs(patterns[s].pattern) do
				match = text:match(p)
				if match ~= nil then
					--Auto-detect word boundaries.
					--We don't want keywords to detect greedily.
					local lookahead_ok = true
					if patterns[s].lookahead ~= nil then
						if text:sub(#match+1, #text):match(patterns[s].lookahead) == nil then
							lookahead_ok = false
						end
					end
					if lookahead_ok and (patterns[s].greedy == true or text:sub(#match, #match+1):match("[%w_][%w_]") == nil) then
						return s, match
					end
				end
			end
		end
	end
	return nil, nil
end

function cur(text, output_index)
	local res
	if output_index <= cursor_pos and (output_index + #text) > cursor_pos then
		res = text:sub(1, cursor_pos - output_index + 1) .. cursor .. text:sub(cursor_pos - output_index + 2, #text)
	else
		res = text
	end

	output_index = output_index + #text
	return res, output_index
end


--Returns colored syntax
--NEEDS TO INJECT THE CURSOR WHEN APPROPRIATE!!!!!!
function PROCESS(text)
	local scope = scopes.initial
	local scope_stack = {}
	local result = ""
	local prev_pattern = {}
	local index = 1

	if cursor_pos == 0 then
		result = cursor
	end

	while #text > 0 do
		local pattern_name = nil
		local match_text = nil

		--Check global scope first if no other scopes are overriding it.
		if #scope_stack == 0 then
			pattern_name, match_text = check_scope(text, scopes.global)
		end

		--Check current scope
		if pattern_name == nil then
			pattern_name, match_text = check_scope(text, scope)
		end

		if pattern_name == nil then
			--no matching pattern found, so just append this char onto the output
			t, index = cur(text:sub(1,1), index)
			result = result .. t
			text = text:sub(2,#text)
		else
			--we found a matching pattern within the current scope!
			local pattern = patterns[pattern_name]

			if pattern.display and theme[pattern.display] then
				result = result .. theme[pattern.display].open
			end

			t, index = cur(match_text, index)
			result = result .. t

			if pattern.scope ~= nil then
				--change the current scope
				scope = scopes[pattern.scope]
			end
			if pattern.push ~= nil then
				--push existing scope onto the stack and set the new scope
				table.insert(scope_stack, scope)
				table.insert(prev_pattern, pattern)
				scope = scopes[pattern.push]
			elseif pattern.display and theme[pattern.display] then
				result = result .. theme[pattern.display].close
			end

			if pattern.pop == true and #scope_stack > 0 then
				--pop a scope off the stack
				scope = table.remove(scope_stack)
				local prev = table.remove(prev_pattern)
				if prev.display and theme[prev.display] then
					result = result .. theme[prev.display].close
				end
			end

			text = text:sub(#match_text+1, #text)
		end
	end --LOOP END

	--Pop all scopes at the end, just in case
	while #scope_stack > 0 do
		scope = table.remove(scope_stack)
		local prev = table.remove(prev_pattern)
		if prev.display and theme[prev.display] then
			result = result .. theme[prev.display].close
		end
	end

	return result
end


--PARSE UPDATED LINES
output(PROCESS(text), 1)