--!strict
local utils = require('./Utils')
local hierarchy = {}

function hierarchy.new()
	local self = {}
	self.parents = {}
	self._cache = {}

	function self:setParent(childType: string, parentType: string)
		local childId = utils.getTypeId(childType)
		local parentId = utils.getTypeId(parentType)
		if not self.parents[childId] then
			self.parents[childId] = {}
		end
		table.insert(self.parents[childId], parentId)
		self._cache = {}
	end

	function self:getParents(typeId: number): {number}
		return self.parents[typeId] or {}
	end

	function self:isDescendantOf(childId: number, parentId: number): boolean
		local cacheKey = childId * 100003 + parentId
		if self._cache[cacheKey] ~= nil then
			return self._cache[cacheKey]
		end

		local visited = {}
		local queue = {childId}
		local result = false

		while #queue > 0 do
			local current = table.remove(queue, 1)
			if visited[current] then
				continue
			end
			visited[current] = true
			if current == parentId then
				result = true
				break
			end
			for _, parent in self:getParents(current) do
				if not visited[parent] then
					table.insert(queue, parent)
				end
			end
		end

		self._cache[cacheKey] = result
		return result
	end

	return self
end

return hierarchy