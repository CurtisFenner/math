local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local Constant = {}
do
	local identifier = 0
	function Constant.new()
		identifier = identifier + 1
		return setmetatable( {identifier = identifier}, Constant)
	end
	--
	function Constant.__tostring(s)
		return "C_" .. s.identifier
	end
	--
	function isConstant(c)
		return getmetatable(c) == Constant
	end
end

local S, isS = unpack(require(dir .. "S"))
local Expression = {}
Expression.Constant = Constant
-- False negatives allowed
function Expression.equal(a, b)
	-- TODO: Compare on a stronger basis than LaTeX
	if isS(a) and isS(b) then
		return a == b or tostring(a) == tostring(b)
	end
	return a == b
end

function Expression.isConstant(v, e)
	if type(e) == "number" or type(e) == "boolean" then
		return true
	end
	if type(e) == "string" then
		-- TODO: manage dependence of variables. e.g., y is not constant with
		-- respect to x in most problems.
	end
	if isConstant(e) then
		return true
	end
	if isS(e) then
		for j = 2, e:size() do
			if not Expression.constant(v, e[j]) then
				return false
			end
		end
		return true
	end
end

-- False negatives allowed
function Expression.notEqual(a, b)
	if type(a) == "number" and type(b) == "number" then
		return a ~= b
	end
end

return Expression
