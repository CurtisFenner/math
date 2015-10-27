
local Expression = {}
-- False negatives allowed
function Expression.equal(a, b)
	return a == b
end

-- False negatives allowed
function Expression.notEqual(a, b)
	if type(a) == "number" and type(b) == "number" then
		return a ~= b
	end
end

return Expression
