local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local S, isS = unpack(require(dir .. "S"))
local Expression = {}
-- False negatives allowed
function Expression.equal(a, b)
	-- TODO: Compare on a stronger basis than LaTeX
	if isS(a) and isS(b) then
		return a == b or tostring(a) == tostring(b)
	end
	return a == b
end

-- False negatives allowed
function Expression.notEqual(a, b)
	if type(a) == "number" and type(b) == "number" then
		return a ~= b
	end
end

return Expression
