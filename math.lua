local Rules = require("rules")
local MinHeap = require("MinHeap")
local S, isS = unpack( require("S") )
local LaTeX = require("Latex")

-- Prefers solving.
function Size(expression)
	-- Subtract two per unique variable
	local bonus = 0
	if isS(expression) then
		-- Discount variables slightly (since answers can be expected to have some small freedoms)
		local k = expression:descendants()
		local seen = {}
		for i = 1, #k do
			if type(k[i]) == "string" then
				if not seen[k[i]] then
					seen[k[i]] = true
					bonus = bonus - 2
				end
			end
			if isS(k[i]) then
				if k[i][1] == "=" then
					bonus = bonus - 1
				end
			end
		end
		-- Compute normal size:
		local s = 1
		for i = 2, expression:size() do
			s = s + Size(expression[i])
		end
		return s + bonus
	else
		return 1 + bonus
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

function Execute(expression, rules, score)
	local begin = os.clock()
	local heap = MinHeap.new(function(a, b) return score(a.expression) < score(b.expression) end)
	local boxed = {expression = expression, step = "input"}
	heap:push(boxed)
	local seen = {}
	seen[ tostring(expression) ] = true
	local best = boxed
	local cycles = 0
	while heap:size() > 0 and cycles < 1000 do
		cycles = cycles + 1
		local t = heap:pop()
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
	print(string.rep(" ", 3 - #tostring(i) ) .. i .. ". " .. t[i].step)
	print("", LaTeX(t[i].expression))
end
print("Answer")
print("", LaTeX(answer.expression))
