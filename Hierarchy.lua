--!strict
local utils = require(script.Parent.Utils)

local hierarchy = {}

function hierarchy.new()
	local self = {}
	self.parents = {}
	
	function self:setParent(childType: string, parentType: string)
		local childId = utils.getTypeId(childType)
		local parentId = utils.getTypeId(parentType)
		if not self.parents[childId] then
			self.parents[childId] = {}
		end
		table.insert(self.parents[childId], parentId)
	end

	function self:getParents(typeId: number): {number}
		return self.parents[typeId] or {}
	end

	function self:isDescendantOf(childId: number, parentId: number): boolean
		if childId == parentId then
			return true
		end
		
		local parents = self:getParents(childId)
		for _, parent in parents do
			
			if self:isDescendantOf(parent, parentId) then
				return true
			end
			
		end
		return false
	end
	return self
end

return hierarchy
