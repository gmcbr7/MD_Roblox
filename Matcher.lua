--!strict
local utils = require('./Utils')
local match = {}

local knownTypes = {
    ["nil"] = true,
    ["boolean"] = true,
    ["number"] = true,
    ["string"] = true,
    ["table"] = true,
    ["function"] = true,
    ["thread"] = true,
    ["userdata"] = true,
    ["vector"] = true,
    ["buffer"] = true,
    ["Instance"] = true,
    ["EnumItem"] = true,
    ["Enum"] = true,
    ["Enums"] = true,
    ["Vector2"] = true,
    ["Vector2int16"] = true,
    ["Vector3"] = true,
    ["Vector3int16"] = true,
    ["CFrame"] = true,
    ["Color3"] = true,
    ["BrickColor"] = true,
    ["UDim"] = true,
    ["UDim2"] = true,
    ["Rect"] = true,
    ["Region3"] = true,
    ["Region3int16"] = true,
    ["NumberSequence"] = true,
    ["ColorSequence"] = true,
    ["NumberSequenceKeypoint"] = true,
    ["ColorSequenceKeypoint"] = true,
    ["NumberRange"] = true,
    ["PhysicalProperties"] = true,
    ["Ray"] = true,
    ["Axes"] = true,
    ["Faces"] = true,
    ["Random"] = true,
    ["DateTime"] = true,
    ["TweenInfo"] = true,
    ["RBXScriptSignal"] = true,
    ["RBXScriptConnection"] = true,
    ["PathWaypoint"] = true,
    ["any"] = true,
}

function match.normalizeSpec(spec: any)
    if spec == nil then
        return {mode = "any"}
    elseif typeof(spec) == "string" then
        if spec == "any" then
            return {mode = "any"}
        elseif knownTypes[spec] then
            return {mode = "type", type = spec, typeId = utils.getTypeId(spec)}
        else
            return {mode = "value", value = spec}
        end
    elseif typeof(spec) == "table" and spec.mode then
        local normalized = spec
        if normalized.mode == "type" and normalized.type then
            normalized.typeId = utils.getTypeId(normalized.type)
        end
        return normalized
    else
        return {mode = "value", value = spec}
    end
end

function match.matches(arg: any, spec: any, hierarchy: any): boolean
	if spec.mode == "any" then
		return true
	elseif spec.mode == "type" then
		local currentTypeId = utils.getArgTypeId(arg)
		local targetTypeId = spec.typeId
		return hierarchy:isDescendantOf(currentTypeId, targetTypeId)
	elseif spec.mode == "value" then
		return arg == spec.value
	end
	return false
end

function match.createHashKey(specs: any): number?
	local hashComponents = {}
	for _, spec in specs do
		if spec.mode ~= "type" then
			return nil
		end
		table.insert(hashComponents, spec.typeId :: number)
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