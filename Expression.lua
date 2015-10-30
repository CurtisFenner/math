local S, isS = unpack(require("S"))
local LaTeX = require("Latex")
local Expression = {}
-- False negatives allowed
function Expression.equal(a, b)
	-- TODO: Compare on a stronger basis than LaTeX
	if isS(a) and isS(b) then
		return a == b or LaTeX(a) == LaTeX(b)
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
