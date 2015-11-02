local dir = ""
for i = #arg[0], 1, -1 do
	if arg[0]:sub(i, i) == "/" then
		dir = arg[0]:sub(1, i)
		break
	end
end

local Operators = require(dir .. "Operators")

local SMethods = {}
local private = {}


function SMethods.clone(self)
	return S(self[private])
end

function SMethods.removed(self, i)
	local k = {unpack(self[private])}
	table.remove(k, i)
	return S(k)
end

function SMethods.valid(self)
	if self:size() <= 1 then
		return false
	end
	local okay = {}
	for i = 1, #self[private] do
		if self[private][i] == nil then
			return false
		end
		okay[i] = true
	end
	if Operators.isBinary(self[1]) then
		if self:size() ~= 3 then
			return false
		end
	end
	for i, v in pairs(self[private]) do
		if not okay[i] then
			return false
		end
	end
	for i = 2, self:size() do
		if isS(self[i]) then
			if not self[i]:valid() then
				return false
			end
		end
	end
	return true
end

function SMethods.pushed(self, e)
	local k = {unpack(self[private])}
	table.insert(k, e)
	return S(k)
end

function SMethods.inserted(self, i, e)
	local k = {unpack(self[private])}
	table.insert(k, i, e)
	return S(k)
end

function SMethods.replaced(self, i, e)
	assert(e ~= nil)
	local k = {}
	for j = 1, self:size() do
		k[j] = self[j]
	end
	k[i] = e
	local s = S(k)
	assert(s[i] == e)
	return s
end

function SMethods.size(self)
	return #self[private]
end

function SMethods.children(self, into)
	into = into or {}
	for i = 2, #self do
		table.insert(into, self[i])
	end
	return into
end

function SMethods.descendants(self, into)
	into = into or {}
	for i = 2, #self do
		table.insert(into, self[i])
		if isS(self[i]) then
			self[i]:descendants(into)
		end
	end
	return into
end

function SMethods.size(self)
	return #self[private]
end

local Smeta = {
	__tostring = function(self)
		local s = "[" .. self[1]
		for i = 2, self:size() do
			s = s .. ", " .. tostring(self[i])
		end
		return s .. "]"
	end,
	__index = SMethods
}

function Smeta.__newindex(self)
	error("S-expressions are immutable", 2)
end

function S(list)
	local d = { unpack(list) }
	local m = {}
	for i, v in pairs(Smeta) do
		m[i] = v
	end
	function m.__index(self, i)
		if i == private then
			return d
		else
			if d[i] == nil then
				return SMethods[i]
			else
				return d[i]
			end
		end
	end
	return setmetatable({}, m)
end

function isS(x)
	return type(x) == "table" and getmetatable(x) and getmetatable(x).__newindex == Smeta.__newindex and x[private]
end

-- Strips whitespace from S-expressions. Returns an S-expression or other
-- primitive
function parseS( str )
	local t = {}
	if str:sub(1, 1) == "[" then
		str = str:gsub("%s+", "")
		assert(str:sub(-1) == "]", "unbalanced braces")
		local opEnd = str:find("[%],]")
		local op = str:sub(2, opEnd - 1)
		t[1] = op
		assert(op and #op > 0, "empty operator")
		local rest = str:sub(opEnd + 1, -2)
		while #rest > 0 do
			if rest:sub(1, 1) == "[" then
				local _, e = rest:find("%b[]")
				assert(e, "unbalanced braces")
				table.insert(t,  parseS( rest:sub(1, e) ) )
				rest = rest:sub(e + 1)
				assert(rest:sub(1, 1) == "," or rest:sub(1, 1) == "]" or rest:sub(1, 1) == "", "invalid S-expression")
				rest = rest:sub(2)
			else
				local k = rest:find("[%],]")
				if not k then
					table.insert(t, parseS( rest) )
					rest = ""
				else
					table.insert(t, parseS( rest:sub(1, k - 1) ) )
					rest = rest:sub(k + 1)
				end
			end
		end
		return S(t)
	else
		if str == "true" then
			return true
		elseif str == "false" then
			return false
		elseif tonumber(str) then
			return tonumber(str)
		else
			return str
		end
	end
end

assert( isS( S{"+", 1, 2}  ) )
assert( not isS( {} ))
assert( not isS( 5 ) )
assert( not isS( "cat" ) )

assert( (S{"+", 1, 2}):size() == 3 )

assert( (S{"+", 1, 2})[1] == "+")
assert( (S{"+", 3, 4})[3] == 4)

assert( not  (S{"+"}):valid()     )
assert( not (S{"+", 3, nil, 5}):valid() )
local u = S {"or", S{"=", 0, "x"}, S{"or", nil, S{"=", S{"*", "y", "x"}, 0}}}
assert( not u:valid() )


return {S, isS, parseS}
