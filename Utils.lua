--!strict
local typeToId = {}
local nextTypeId = 1
local instanceToId = {}
local nextInstanceId = 1
local utils = {}

-- written w the help of my brother (he helped me with logic, i did the typing)
function utils.getTypeId(typeName: string): number
	if not typeToId[typeName] then
		typeToId[typeName] = nextTypeId
		nextTypeId += 1
	end
	
	return typeToId[typeName]
end
function utils.getInstanceId(instance: Instance): number
	if not instanceToId[instance] then
		instanceToId[instance] = nextInstanceId
		nextInstanceId += 1
	end
	
	return instanceToId[instance]
end

-- TODO: prevent collision with string hashing
function utils.getValueId(value: any): number
	if typeof(value) == "Instance" then
		return utils.getInstanceId(value) + 100000
	elseif typeof(value) == "number" then
		return math.floor(value * 100) % 50000
	elseif typeof(value) == "string" then
		local hash = 0
		for i = 1, #value do
			hash = (hash * 37 + string.byte(value, i)) % math.huge
		end
		return hash
	elseif typeof(value) == "boolean" then
		return value and 1 or 0
	else
		return 0
	end
end
function utils.combineHashes(nums: {number}): number
	local hash = 17
	for _, num in nums do
		hash = ((hash * 41) + num) % 1000000
	end
	
	return hash
end

function utils.getArgType(arg: any): string
	return typeof(arg) == "Instance" and arg.ClassName or typeof(arg)
end
function utils.getArgTypeId(arg: any): number
	return utils.getTypeId(utils.getArgType(arg))
end
return utils
