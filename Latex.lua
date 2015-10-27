local S, isS = unpack( require("S") )
--
local infixes = {"+", "*", "<=", ">=", "<", ">", "=", "~=", "and", "or", "implies"}
local unary = {"-", "not"}
local replacement = {
	-- infix
	["<="] = "\\leq",
	[">="] = "\\geq",
	["~="] = "\\neq",
	-- infix words
	["not"] = "\\text{ not }",
	["and"] = "\\text{ and }",
	["or"] = "\\text{ or }",
	-- infix words
	["implies"] = "\\implies ",
	-- functions
	["log"] = "\\log ",
}

local precedence = {
	["not"] = 2,
	["-"] = 2,
	["/"] = 2,
	["*"] = 3,
	["+"] = 4,
	["="] = 6,
	[">"] = 6,
	["<"] = 6,
	["<="] = 6,
	[">="] = 6,
	["~="] = 6,
	["and"] = 11,
	["or"] = 12,
}

-- Tests wheter `op` is a unary operator
local function isUnary(op)
	for i = 1, #unary do
		if op == unary[i] then
			return true
		end
	end
end

-- Tests whether `op` is an infix operator (+ is, (unary) - is not, etc)
local function isInfix(op)
	for i = 1, #infixes do
		if infixes[i] == op then
			return true
		end
	end
end

-- Produces a string of LaTex (math mode) code representing expression `ex`
function Latex(ex, pre)
	if type(ex) == "boolean" then
		return ex and "\\text{True}" or "\\text{False}"
	elseif type(ex) == "number" or type(ex) == "string" then
		return tostring(ex)
	end
	if isS(ex) then
		pre = pre or math.huge
		local op = ex[1]
		local t = {}
		local sep = ", "
		local pre, post = "", ""
		local p = precedence[op]
		assert(not (isInfix(op) or isUnary(op)) or p, "no precedence specified for '" .. op .. "'")
		if isInfix(op) then
			if precedence[op] > p then
				pre, post = "(", ")"
			end
			sep = " " .. (replacement[op] or op) .. " "
		elseif isUnary(op) then
			if precedence[op] > p then
				pre, post = "(", ")"
			end
			pre = pre .. op .. " "
		else
			pre, post = (replacement[op] or op) .. "(", ")"
		end
		for i = 2, ex:size() do
			t[i-1] = Latex(ex[i], isInfix(op) and p)
		end
		return "{" .. pre .. table.concat(t, sep) .. post .. "}"
	else
		-- TODO: come up with a standard way to LaTeX special objects.
	end
end

return Latex
