--!strict
local types = require(script.Parent.Types)
local utils = require(script.Parent.Utils)

type matchSpec = types.matchSpec

local match = {}

function match.normalizeSpec(spec: any): matchSpec
	if spec == nil then
		return {mode = "any"}
	elseif typeof(spec) == "string" then
		if spec == "any" then
			return {mode = "any"}
		else
			return {mode = "type", type = spec, typeId = utils.getTypeId(spec)}
		end
	elseif typeof(spec) == "table" and spec.mode then
		
		local normalized = spec :: matchSpec
		if normalized.mode == "type" and normalized.type then
			normalized.typeId = utils.getTypeId(normalized.type)
		end
		return normalized
		
	else
		return {mode = "value", value = spec}
	end
end

function match.matches(arg: any, spec: matchSpec, hierarchy: any): boolean
	if spec.mode == "any" then
		return true
	elseif spec.mode == "type" then
		local currentTypeId = utils.getArgTypeId(arg)
		local targetTypeId = spec.typeId

		local visited = {}
		local queue = {currentTypeId}

		while #queue > 0 do
			local checkingTypeId = table.remove(queue, 1)

			if visited[checkingTypeId] then
				continue
			end
			visited[checkingTypeId] = true

			if checkingTypeId == targetTypeId then
				return true
			end

			local parents = hierarchy:getParents(checkingTypeId)
			for _, parentId in parents do
				table.insert(queue, parentId)
			end
			
		end

		return false
	elseif spec.mode == "value" then
		return arg == spec.value
	end
	return false
end



function match.createHashKey(specs: {matchSpec}): number?
	local hashComponents = {}

	for _, spec in specs do
		if spec.mode == "any" then
			return nil
		elseif spec.mode == "type" then
			table.insert(hashComponents, spec.typeId :: number)
		elseif spec.mode == "value" then
			table.insert(hashComponents, utils.getValueId(spec.value))
		end
	end

	return utils.combineHashes(hashComponents)
end

function match.createRuntimeKey(args: {any}): number
	local hashComponents = {}

	for _, arg in args do
		table.insert(hashComponents, utils.getArgTypeId(arg))
	end

	return utils.combineHashes(hashComponents)
end

return match
