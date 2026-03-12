--!strict
local utils = {}
local typeIds: {[string]: number} = {}
local valueIds: {[any]: number} = {}
local nextId = 1

local function newId(): number
	local id = nextId
	nextId += 1
	return id
end

function utils.getTypeId(typeName: string): number
	if not typeIds[typeName] then
		typeIds[typeName] = newId()
	end
	return typeIds[typeName]
end

function utils.getArgType(arg: any): string
	return typeof(arg)
end

function utils.getArgTypeId(arg: any): number
	return utils.getTypeId(typeof(arg))
end

function utils.getValueId(value: any): number
	if not valueIds[value] then
		valueIds[value] = newId()
	end
	return valueIds[value]
end

function utils.combineHashes(components: {number}): number
	local hash = 0
	for _, component in components do
		hash = hash * 31 + component
	end
	return hash
end

return utils