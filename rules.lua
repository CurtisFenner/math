
--[[

Task:
	Simplify
	Solve
	Factor
	Integrate


Problem:
	solves:    Problem
	index:     Any (identifies purpose in parent problem)
	remaining: Integer (identifies number remaining)
	solved:    Dictionary[ index ] -> Subproblem
	task:      Enum (string) identifiying task
	solution:  Value resulted from solving task
]]

local Expression = require("Expression")
local Operators = require("Operators")
local S, isS = unpack( require("S") )
--
local Rules = {}
--

function clone(S)
	return {unpack(S)}
end


--------------------------------------------------------------------------------
-- Logic:

function Rules.LogicSame(s)
	if s[1] == "and" or s[1] == "or" then
		if Expression.equal( s[2], s[3]   ) then
			return {s[2], s[3]}
		end
	end
	return {}
end

function Rules.LogicIdentities(s)
	if s[1] == "and" then
		if Expression.equal(s[1], false) then
			return {false}
		elseif Expression.equal(s[1], true) then
			return {s[2]}
		elseif Expression.equal(s[2], false) then
			return {false}
		elseif Expression.equal(s[2], true) then
			return {s[1]}
		end
	elseif s[1] == "or" then
		if Expression.equal(s[1], false) then
			return {s[2]}
		elseif Expression.equal(s[1], true) then
			return {true}
		elseif Expression.equal(s[2], false) then
			return {s[1]}
		elseif Expression.equal(s[2], true) then
			return {true}
		end
	elseif s[1] == "implies" then
		if Expression.equal(s[3], false) then
			return {S{"not", s[2]}}
		elseif Expression.equal(s[3], true) then
			return {true}
		end
	end
	return {}
end


--------------------------------------------------------------------------------



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

function Rules.NotNot(s)
	if s:size() == 2 then
		if isS(s[2]) and s[2]:size() == 2 and Operators.isUnaryInverse(s[1], s[2][1]) then
			return {s[2][2]}
		end
	end
	return {}
end

function Rules.Merge(s)
	-- TODO: fix me to be *associative*
	local op = s[1]
	if Operators.isCommutative(op) then
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
	if Operators.isCommutative(op) then
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
						table.insert(R, k)
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
		return { S{s[1],    Operators.getIdentity(s[1] ) } }
	end
	if #t < s:size() then
		return { S(t) }
	else
		return {}
	end
end

--
return Rules
