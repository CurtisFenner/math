local Rules = require("rules")
local MinHeap = require("MinHeap")
local S, isS = unpack( require("S") )
local LaTeX = require("Latex")

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

function transform(ex, rules)
	local r = {}
	for name, rule in pairs(rules) do
		for _, v in pairs( rule(ex)  ) do
			if type(v) == "table" then
				rawset(v, "step", name)
			end
			if type(v) == "table" and not isS(v) then
				print(name)
			end
			table.insert(r, v)
		end
	end
	return r
end

function handle(ex, rules)
	if isS(ex) then
		local r = transform(ex, rules)
		for i = 2, ex:size() do
			local m = handle(ex[i], rules)
			for _, s in pairs(m) do
				local g = ex:replaced(i, s)
				if type(s) == "table" then
					rawset(g, "step", s.step)
				end
				table.insert(r, g )
			end
		end
		return r
	else
		return {}
	end
end

function Execute(expression, rules, score)
	local begin = os.clock()
	local heap = MinHeap.new(function(a, b) return score(a) < score(b) end)
	heap:push(expression)
	local seen = {}
	seen[ tostring(expression) ] = true
	local best = expression
	local cycles = 0
	while heap:size() > 0 and cycles < 100 do
		cycles = cycles + 1
		local t = heap:pop()
		local f = type(t) == "table" and t.step or ""
		f = f .. string.rep(" ", 20 - #f)
		--print("", f .. tostring(t))
		if not isS(t) or score(t) <= 1 then
			return t
		end
		if score(t) < score(best) then
			best = t
		end
		--
		local vs = handle(t, rules)
		for _, v in pairs(vs) do
			local key = tostring(v)
			if not seen[key] then
				heap:push( v )
				seen[ key ] = true
			end
		end
	end
	print("Elapsed:", os.clock() - begin)
	return best
end

--------------------------------------------------------------------------------

local input = S {"=", S{"+", "x", S{"log", "y"} }, 0  }

local answer = Execute(input, Rules, Size)
print("Input")
print("", LaTeX(input))
print("Answer")
print("", LaTeX(answer))
