local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local S, isS = unpack( require(dir .. "S") )
local Operators = require(dir .. "Operators")
local Expression = require(dir .. "Expression")

-- Intersects lists of expressions
function intersection(a, b)
	local r = {}
	for i = 1, #a do
		for j = 1, #b do
			if Expression.equal(a[i], b[j]) then
				table.insert(r, a[i])
			end
		end
	end
	return r
end

function Factors(s, op)
	-- Return things that divide s
	if type(s) == "string" then
		return {s}
	end
	if isS(s) then
		if Operators.distributes(op, s[1]) then
			local t = Factors(s[2], op)
			for j = 3, s:size() do
				t = intersection(t, Factors(s[j], op))
			end
			return t
		end
	end
	return {}
end

return Factors