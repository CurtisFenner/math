local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local Rules = require(dir .. "Rules")
local MinHeap = require(dir .. "MinHeap")
local S, isS, parseS = unpack( require(dir .. "S") )
local Operators = require(dir .. "Operators")

local params = {unpack(arg)}

VERBOSE = params[1] == "verbose"
if VERBOSE then
	table.remove(params, 1)
end

INTERACTIVE = params[1] == "interactive"
if INTERACTIVE then
	table.remove(params, 1)
end

-- Prefers solving.
function Size(expression, data)
	data = data or {
		seen = {}
	}
	-- Subtract two per unique variable
	if isS(expression) then
		-- Compute normal size:
		local bonus = 0
		if expression[1] == "=" or expression[1] == "or" or expression[1] == "and" then
			bonus = -0.9
		end
		if Operators.isAssociative( expression[1] ) and expression:size() == 2 then
			return Size(expression[2], data) + 0.1
		end
		if expression[1] == "=" then
			if not isS(expression[2]) or not isS(expression[3]) then
				bonus = bonus - 0.9
			end
		end
		local s = 1
		for i = 2, expression:size() do
			s = s + Size(expression[i], data)
		end
		return s + bonus
	else
		if type(expression) == "string" then
			-- Variables are OK the first time, since, they're hard to eliminate in general.
			if not data.seen[expression] then
				data.seen[expression] = true
				return 0.6
			end
		end
		return 1
	end
end

--------------------------------------------------------------------------------


function transform(box, rules)
	local r = {}
	for name, rule in pairs(rules) do
		local m = rule(box.expression)
		assert(m, "must return value from rule " .. name)
		assert(type(m) == "table", "must return table from rule " .. name)
		assert(not getmetatable(m), "must return list (not object) from rule " .. name)
		for _, v in pairs( m ) do
			if isS(v) then
				assert(v:valid(), name .. " produced in valid expression " .. tostring(v))
			end
			local t = {
				step = name,
				expression = v,
				parent = box,
			}
			table.insert(r, t)
		end
	end
	return r
end

function handle(box, rules)
	if isS(box.expression) then
		local r = transform(box, rules)
		for i = 2, box.expression:size() do
			local subBoxes = handle({expression = box.expression[i], parent = box.parent, step = box.step}, rules)
			for _, subBox in pairs(subBoxes) do
				table.insert(r, {
					expression = box.expression:replaced(i, subBox.expression),
					step = subBox.step,
					parent = box,
				})
			end
		end
		return r
	else
		return {}
	end
end

function string.padRight(str, c, n)
	local m = n - #str
	return str .. c:rep(m):sub(1, m)
end

function Interactive(expression, rules, score)
	local step = 0
	while true do
		step = step + 1
		print("\n" .. step .. ".", expression )
		local r = handle({ expression = expression, step = "interactive" }, rules)
		table.sort(r, function(a, b)
			return score(a.expression) < score(b.expression)
		end)
		for i = 1, #r do
			print("", i .. ")", r[i].step:padRight(" ", 20) , r[i].expression)
		end
		local choice
		repeat
			io.write("> ")
			local line = io.read("*line")
			if line == "done" or line == "quit" or line == "exit" then
				return
			end
			choice = tonumber( line )
			print(choice)
		until choice and r[choice]
		expression = r[choice].expression
	end
end

function Execute(expression, rules, score)
	local begin = os.clock()
	local heap = MinHeap.new(function(a, b) return score(a.expression) < score(b.expression) end)
	local boxed = {expression = expression, step = "input"}
	heap:push(boxed)
	local seen = {}
	seen[ tostring(expression) ] = true
	local best = boxed
	local cycles = 0
	--local lastScore
	while heap:size() > 0 and cycles < 1000 do
		cycles = cycles + 1
		local t = heap:pop()
		--local ss = score(t.expression)
		--if ss ~= lastScore then
		--	print(ss)
		--end
		--lastScore = ss
		--local f = t.step
		--f = f .. string.rep(" ", 20 - #f)
		--print("", f .. tostring(t.expression))
		--if not isS(t.expression) or score(t.expression) < 2 then
		--	print("Perfect!")
		--	return t
		--end
		if score(t.expression) < score(best.expression) then
			best = t
		end
		--
		local bs = handle(t, rules)
		for _, b in pairs(bs) do
			local key = tostring(b.expression)
			if not seen[key] then
				if VERBOSE then
					print(key)
				end
				heap:push( b )
				seen[ key ] = true
			end
		end
	end
	return best
end

--------------------------------------------------------------------------------

local input = "" -- S {"=", S{"*", "x", 5, "x", "y", "z"}, 0 }
for i = 1, #params do
	input = input .. params[i] .. " "
end

if INTERACTIVE then
	if not input:find("%S") then
		print("Enter S-expression:")
		io.write("> ")
		input = io.read("*line")
	end
	input = parseS(input)
	Interactive(input, Rules, Size)
else
	assert(input:find("%S"), "must specify expression")
	input = parseS(input)
	local answer = Execute(input, Rules, Size)
	--
	local t = {}
	local box = answer
	while box do
		table.insert(t, 1, box)
		box = box.parent
	end
	for i = 1, #t do
		print("- " .. t[i].step)
		print("", t[i].expression)
	end
end
