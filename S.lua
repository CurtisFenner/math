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
	return self:removed(i):inserted(i, e)
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
	local m = {
	}
	for i, v in pairs(Smeta) do
		m[i] = v
	end
	function m.__index(self, i)
		if i == private then
			return d
		else
			return d[i] or SMethods[i]
		end
	end
	return setmetatable({}, m)
end

function isS(x)
	return type(x) == "table" and getmetatable(x) and getmetatable(x).__newindex == Smeta.__newindex and x[private]
end

assert( isS( S{"+", 1, 2}  ) )
assert( not isS( {} ))
assert( not isS( 5 ) )
assert( not isS( "cat" ) )

assert( (S{"+", 1, 2}):size() == 3 )

assert( (S{"+", 1, 2})[1] == "+")
assert( (S{"+", 3, 4})[3] == 4)

return {S, isS}
