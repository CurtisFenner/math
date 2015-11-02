local Rules = require("rules")
local MinHeap = require("MinHeap")
local S, isS = unpack( require("S") )
local LaTeX = require("Latex")
local Operators = require("Operators")

local INTERACTIVE = false
for i = 1, #arg do
	if arg[i]:find("interactive") then
		INTERACTIVE = true
	end
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
			return Size(expression[2], data)
		end
		if expression[1] == "=" then
			if not isS(expression[2]) or not isS(expression[3]) then
				bonus = bonus - 1
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
			io.write(">")
			choice = tonumber( io.read("*line") )
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
	local lastScore
	while heap:size() > 0 and cycles < 1000 do
		cycles = cycles + 1
		local t = heap:pop()
		local ss = score(t.expression)
		if ss ~= lastScore then
			print(ss)
		end
		lastScore = ss
		--local f = t.step
		--f = f .. string.rep(" ", 20 - #f)
		--print("", f .. tostring(t.expression))
		if not isS(t.expression) or score(t.expression) < 2 then
			print("Perfect!")
			return t
		end
		if score(t.expression) < score(best.expression) then
			best = t
		end
		--
		local bs = handle(t, rules)
		for _, b in pairs(bs) do
			local key = tostring(b.expression)
			if not seen[key] then
				--print(key)
				--[[if key:find("nil") then
					print("NIL FROM: ", b.step)
					print("GOOD: ", t.expression)
					print("BAD:  ", b.expression)
					print("BAD P:", b.parent.step, b.parent.parent.expression)
				end]]
				heap:push( b )
				seen[ key ] = true
			end
		end
	end
	print("Elapsed:", os.clock() - begin, score(best.expression))
	return best
end

--------------------------------------------------------------------------------

local input = S {"=", S{"*", "x", 5, "x", "y", "z"}, 0 }

--input = S{"=", S{"*", "x", "y"}, 0}

local correct = S{"or",  S{"or",  S{"=", "x", 0}, S{"=", "y", 0}    } , S{"=", "z", 0}    }
print("Correct score:", Size( correct ) )

if INTERACTIVE then
	Interactive(input, Rules, Size)
end
local answer = Execute(input, Rules, Size)
print("Input")
print("", LaTeX(input))
--
local t = {}
local box = answer
while box do
	table.insert(t, 1, box)
	box = box.parent
end
for i = 1, #t do
	--print(string.rep(" ", 3 - #tostring(i) ) .. i .. ". " .. t[i].step)
	print("\\item   " .. t[i].step)
	print("$$", LaTeX(t[i].expression), "$$")
end
print("Answer")
print("", LaTeX(answer.expression))
