local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local Expression = require(dir .. "Expression")
local Factor = require(dir .. "Factor")
local Operators = require(dir .. "Operators")
local S, isS = unpack( require(dir .. "S") )


--
local Rules = {}
--

function clone(S)
	return {unpack(S)}
end

--------------------------------------------------------------------------------

-- Replace S with X * Y.
function Rules.Factor(s)
	local ps = {"*"}
	local r = {}
	for _, p in pairs(ps) do
		local k = Factor(s, p)
		for i = 1, #k do
			table.insert(r, S{"*", k[i], S{"*", S{"/", k[i]}, s} })
		end
	end
	return r
end

-- Replace AX + AY with A(X + Y)
function Rules.Undistribute(s)
	local r = {}
	for _, mul in pairs( Operators.whichDistributeOver(s[1]) ) do
		local factors = Factors(s, mul)
		for _, factor in pairs(factors) do
			local inv = S{ Operators.getInverse(mul), factor }
			local a = s:clone()
			for i = 2, s:size() do
				a = a:replaced(i, S{mul, inv, s[i] })
			end
			table.insert(r, S{mul, factor, a })
		end
	end
	return r
end

print("###")
x = S{"+", S{"*", "x", "x"}, "x"}
for _, a in pairs( Rules.Undistribute(x) ) do
	print("+", a)
end
print("###")

--------------------------------------------------------------------------------

-- This is an "if then else" function, not an implication.
-- Useful in the definition of abs, for example.
function Rules.If(s)
	if s[1] == "if" then
		if Expression.equal(s[2], true) then
			return {s[3]}
		elseif Expression.equal(s[2], false) then
			return {s[4]}
		elseif Expression.equal(s[3], s[4]) then
			return {s[3]}
		end
	end
	return {}
end

--------------------------------------------------------------------------------
-- Differentiation:

function Rules.DifferentiateSum(s)
	if s[1] == "d" then
		if isS(s[3]) and s[3][1] == "+" then
			-- TODO: check differentiability of functions
			local t = {}
			for i = 2, s[3]:size() do
				t[i-1] = S{"+", S{"d", s[2], s[3][i]},   S{"d", s[2], s[3]:removed(i) } }
			end
			return t
		end
	end
	return {}
end

--------------------------------------------------------------------------------
-- Integration:

-- Taken from Slagle, 1961, SAINT:
-- a) c dv = cv
function Rules.IntegrateConstant(s)
	if s[1] == "int" then
		if Expression.isConstant(s[2], s[3]) then
			return {S{"+", S{"*", s[3], s[2]}, Expression.Constant.new()}}
		end
	end
	return {}
end

-- b) e^v dv = e^v
function Rules.IntegrateExponent(s)
	return {} -- TODO
end

-- c) c^v dv = c^v / ln c

-- t) dv / v = log v
function Rules.IntegrateInverse(s)
	if s[1] == "int" then
		if isS( s[3] ) and s[3][1] == "/" then
			if Expression.equal(s[2], s[3][2]) then
				return {
					S{"+", S{"log", s[2]}, Expression.Constant.new()},
				}
			end
		end
	end
	return {}
end

-- "algorithm like transformations":

-- a) (c*g dv) = c (g dv)
function Rules.IntegrateScaled(s)
	if s[1] == "int" then
		if isS(s[3]) and s[3][1] == "*" then
			for i = 2, s[3]:size() do
				if Expression.isConstant(s[2], s[3][i]) then
					return {
						S{"*", s[3][i],  S{"int", s[2],   s[3]:removed(i) } },
					}
				end
			end
		end
	end
	return {}
end

-- b)
function Rules.IntegrateNegate(s)
	if s[1] == "int" then
		if isS(s[3]) and s[3][1] == "-" then
			return {
				S{"-", S{"int", s[2], s[3][2]}},
			}
		end
	end
	return {}
end

-- c) decompose
function Rules.IntegrateSum(s)
	if s[1] == "int" then
		if isS(s[3]) and s[3][1] == "+" then
			local t = {}
			for i = 2, s[3]:size() do
				t[i-1] = S{"+", s[3][i], S{"int", s[2], s[3]:removed(i)}}
			end
			return t
		end
	end
	return {}
end

-- d) linear substitution: TODO

-- f) f: factors in denominator / numerator



--------------------------------------------------------------------------------
-- Logic:

function Rules.LogicSame(s)
	if s[1] == "and" or s[1] == "or" then
		for i = 2, s:size() do
			for j = i+1, s:size() do
				if Expression.equal(s[i], s[j]) then
					return {
						s:removed(i),
						s:removed(j),
					}
				end
			end
		end
	end
	return {}
end


--------------------------------------------------------------------------------
-- Solving equations:

function Rules.ZeroProduct(s)
	if s[1] == "=" then
		local left, right = s[2], s[3]
		if Expression.equal(left, 0) and isS(right) then
			if right[1] == "*" and right:size() > 2 then
				if right:size() == 3 then
					return {
						S{"or", S{"=", 0, right[2]}, S{"=", 0, right[3]}}
					}
				end
				local K = S{"or", S{"=", 0, right:removed(2)}, S{"=", 0, right[2]} }
				return {K}
			end
		end
	end
	return {}
end


--------------------------------------------------------------------------------
-- Equivalent equations:

function Rules.Reflexive(s)
	if Operators.isReflexive(s[1]) and Expression.equal(s[2], s[3]) then
		return {true}
	end
	if Operators.isReflexive(s[1]) and Expression.notEqual(s[2], s[3]) then
		return {false}
	end
	return {}
end

function Rules.Symmetric(s)
	if Operators.isSymmetric(s[1]) then
		return {   S{s[1], s[3], s[2]}   }
	end
	return {}
end

function Rules.Additive(s)
	local r = {}
	if s[1] == "=" then
		-- TODO... generalize this
		if isS(s[2]) then
			if s[2][1] == "+" then
				local add = s[2][1]
				local inv = Operators.getInverse(add)
				for j = 2, s[2]:size() do
					local m = S{s[1], S{add, s[2], S{inv, s[2][j]}  } , S{add, s[3], S{inv, s[2][j]} }  }
					table.insert(r, m)
				end
			end
		end
	end
	return r
end

function Rules.NegativeIdentity(s)
	local o = Operators.inverseOf(s[1])
	if o then
		local i = Operators.getIdentity(o)
		if Expression.equal(s[2], i) then
			return {i}
		end
	end
	return {}
end

function Rules.Negate(s)
	-- TODO: determine based on types which invertible functions can be applied...
	-- = can specify it's operands types? That seems elegant.
	local fs = Operators.getInvertibleFunctions(s[1])
	local t = {}
	for i = 1, #fs do
		table.insert(t, S{s[1], S{fs[i], s[2]}, S{fs[i], s[3]} } )
	end
	return t
end

--------------------------------------------------------------------------------
-- Arithmetic simplification:

function Rules.Annihiliation(s)
	local e = Operators.getAnnihilator(s[1])
	if e == nil then
		return {}
	end
	for i = 2, s:size() do
		if Expression.equal(s[i], e) then
			print("annihilate", s[1])
			return { S{s[1], e} }
		end
	end
	return {}
end

function Rules.NotNot(s)
	if s:size() == 2 then
		if isS(s[2]) and s[2]:size() == 2 and Operators.isUnaryInverse(s[1], s[2][1]) then
			return {s[2][2]}
		end
	end
	return {}
end

function Rules.flip(s)
	local op = s[1]
	if Operators.isCommutative(op) and s:size() == 3 then
		return {
			S{ op, s[3], s[2] }
		}
	end
	return {}
end

function Rules.Merge(s)
	-- TODO: fix me to be *associative*
	local op = s[1]
	if Operators.isCommutative(op) and Operators.isVariadic(op) then
		local r = {}
		for i = 2, s:size() do
			if isS(s[i]) and s[i][1] == op then
				local m = s:removed(i)
				for j = 2, s[i]:size() do
					m = m:pushed(s[i][j])
				end
				table.insert(r, m)
			end
		end
		return r
	end
	return {}
end

function Rules.LoneOperand(s)
	local op = s[1]
	if Operators.isAssociative(op) then
		if s:size() == 2 then
			return {s[2]}
		end
	end
	return {}
end

function Rules.SimplifyInverse( s )
	local op = s[1]
	local R = {}
	if Operators.isCommutative(op) then
		local inv = Operators.getInverse(op)
		local iden = Operators.getIdentity(op)
		assert(iden ~= nil, "must have identity if has inverse")
		-- TODO: make a distinction between right and left inverse
		-- (doesn't matter for commutative case, anyway)
		for i = 2, s:size() do
			for j = 2, s:size() do
				if i ~= j and isS(s[j]) then
					if s[j][1] == inv and Expression.equal( s[i], s[j][2]   ) then
						local f = 0
						if j > i then
							f = 1
						end
						local k = s:removed(i):removed(j - f)
						if k:size() == 1 then
							table.insert(R, iden)
						else
							table.insert(R, k)
						end
					end
				end
			end
		end
	end
	return R
end

function Rules.SimplifyIdentity( s )
	if s:size() == 2 then
		return {}
	end
	local t = { s[1] }
	for i = 2, s:size() do
		if not Operators.isIdentity(s[1], s[i]) then
			table.insert(t, s[i])
		end
	end
	if #t == 1 then
		local i = Operators.getIdentity(s[1])
		assert(i ~= nil)
		return { S{s[1], i } }
	end
	if #t < s:size() then
		return { S(t) }
	else
		return {}
	end
end

--
return Rules
