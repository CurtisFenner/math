local Operators = {}

function Operators.isBinary(op)
	return false
end

function Operators.distributes(a, over)
	if over == "+" then
		return a == "*"
	end
	return false
end

function Operators.whichDistributeOver(a)
	if a == "+" then
		return {"*"}
	end
	return {}
end

function Operators.preservesIntegers(op)
	return op == "-" or op == "+" or op == "*"
end

function Operators.getAnnihilator(op)
	if op == "and" then
		return false
	elseif op == "or" then
		return true
	elseif op == "*" then
		return 0
	end
end

function Operators.isAssociative(op)
	return op == "or" or op == "and" or op == "+" or op == "*"
end

function Operators.isVariadic(op)
	return op == "+" or op == "*" or op == "and" or op == "or"
end

function Operators.isReflexive(op)
	return op == "=" or op == ">=" or op == "<="
end

function Operators.isAntiReflexive(op)
	return op == "<" or op == ">"
end

function Operators.isSymmetric(op)
	return op == "="
end

function Operators.isCommutative(op)
	return op == "+" or op == "or" or op == "and" or op == "*"
end

function Operators.getIdentity(op, value)
	if op == "and" then
		return true
	elseif op == "or" then
		return false
	elseif op == "+" then
		return 0
	elseif op == "*" then
		return 1
	end
end

-- Returns a list of functions which are invertible under the relation rel.
-- Specifically, returns F iff
-- a rel b === F(a) rel F(b)
function Operators.getInvertibleFunctions(rel)
	-- TODO:
	if rel == "=" then
		return {"-"}
	end
	return {}
end

function Operators.isUnaryInverse(a, of)
	return (a == "-" and of == "-") or (a == "not" and of == "not")
end

function Operators.isSelfInverse(op)
	return op == "-" or op == "not" -- TODO: deal with adding CONDITIONS (e.g., /0)
end

function Operators.inverseOf(op)
	if op == "-" then
		return "+"
	elseif op == "/" then
		return "*"
	end
end

-- TODO: Differentiate left/right operators
function Operators.getInverse(op)
	if op == "+" then
		return "-"
	elseif op == "*" then
		return "/" -- TODO better op name
	end
end

function Operators.isIdentity(op, value)
	return value == Operators.getIdentity(op)
end

return Operators
