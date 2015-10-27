local MinHeap = {}
MinHeap.__index = MinHeap
MinHeap.__tostring = function(h)
	return "Heap[]"
end

function MinHeap.new(comparator)
	return setmetatable({ comparator = comparator, array = {} }, MinHeap)
end

function MinHeap.top(q)
	return q.array[1]
end

local function valid(q, i)
	return 1 <= i and i <= #q.array
end

local function parent(i)
	return math.floor(i / 2)
end
local function left(i)
	return i * 2
end
local function right(i)
	return i * 2 + 1
end
local function swap(q, a, b)
	q.array[a], q.array[b] = q.array[b], q.array[a]
end

local function fixUp(q, i)
	local p = parent(i)
	if not valid(q, p) then
		return
	end
	if q.comparator( q.array[i] , q.array[p] ) then
		swap(q, i, p)
		return fixUp(q, p)
	end
end

local function fixDown(q, i)
	local a, b = left(i), right(i)
	if valid(q, b) then
		if q.comparator( q.array[a], q.array[b] ) then
			if q.comparator( q.array[a], q.array[i] ) then
				swap(q, a, i)
				fixDown(q, a)
			end
		else
			if q.comparator( q.array[b], q.array[i] ) then
				swap(q, b, i)
				fixDown(q, b)
			end
		end
	elseif valid(q, a) then
		if q.comparator( q.array[a], q.array[i] ) then
			swap(q, a, i)
			fixDown(q, a)
		end
	end
end

function MinHeap.pop(q)
	local e = q.array[1]
	q.array[1] = q.array[#q.array]
	table.remove(q.array)
	fixDown(q, 1)
	return e
end

function MinHeap.push(q, e)
	table.insert(q.array, e)
	fixUp(q, #q.array)
end

function MinHeap.size(q)
	return #q.array
end

return MinHeap
