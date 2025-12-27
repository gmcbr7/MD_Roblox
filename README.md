# Multiple Dispatch Library for Roblox

A simple, yet powerful Multiple Dispatch (MD) service for Roblox that lets you define different function behaviors based on argument types, values, and hierarchies.

**Created by:** GMC! (eclipysus on Discord)

> I'm relatively new to coding (~6 months), and this is just a V1. I plan on reworking this later on when I'm somewhat more experienced. If you have any feedback, please DM me! Any type of help is greatly appreciated.

**Special thanks to:** My brother! He taught me (and even recommended me some books) about MD and how languages like CommonLisp use them.

---

## What is Multiple Dispatch?

Instead of writing if-statements over and over to handle different argument types, MD automatically routes to the correct function based on what arguments are passed in.

### Traditional Approach
```lua
function attack(a, b)
	if typeof(a) == "Player" and b.ClassName == "Part" then
		function1()
	elseif typeof(a) == "Player" and b.ClassName == "Model" then
		function2()
	elseif ...
	end
end
```

### With MD
```lua
attack:register({"Player", "Part"}, function(player, part)
	function1()
end)

attack:register({"Player", "Model"}, function(player, model)
	function2()
end)
```

---

## Basic Usage

```lua
local MD = require(game.ReplicatedStorage.MD)

local example = MD.new()

example:register({"Player", "Part"}, function(player, part)
	print(player.Name .. " touched a Part!")
end)

example:register({"Player", "Model"}, function(player, model)
	print(player.Name .. " touched the model: " .. model.Name)
end)

local player = game.Players.LocalPlayer
example(player, game.Workspace.somePart)
example(player, game.Workspace.someModel) -- uses metatable __call so you can call it just like a function!
```

---

## Features

### Hierarchy System

Basic hierarchy system: if a child isn't equal in type or value to a registered function, it checks the parents until it finds a match!

```lua
local combat = MD.new()

combat:setHierarchy("Part", "BasePart")
combat:setHierarchy("MeshPart", "BasePart")
combat:setHierarchy("WedgePart", "BasePart")

combat:register({"Player", "BasePart"}, function(player, part)
print("Works with ANY BasePart child!")
end)

combat(player, workspace.Part)
combat(player, workspace.MeshPart)
combat(player, workspace.WedgePart)
```

**Hierarchy step by step:**
1. Checks if Part == BasePart > false
2. Gets Part's parents → [BasePart]
3. Checks if BasePart == BasePart > true!
4. Executes function

### Value Matching

Match specific instances or values, not just types!

```lua
local doors = MD.new()

doors:register({
	{mode = "value", value = game.Workspace.specialDoor},
	"Player"
}, function(door, player)
	print("THE special door was opened!")
end)

doors:register({"Model", "Player"}, function(door, player)
	print("A regular door was opened")
end)

doors(game.Workspace.specialDoor, player)
doors(game.Workspace.regularDoor, player)
```

> Hmmm... I wonder what game that uses a lot of doors could find this useful? 🤔

### Any Matching

Any type will do!

```lua
local inventory = MD.new()

inventory:register({"Player", "any"}, function(player, item)
	print(player.Name .. " picked up an item!")
end)

inventory(player, workspace.Sword)
inventory(player, workspace.Potion)
inventory(player, 12345)
inventory(player, "anything works!")
```

### Variable Arguments

Functions support any amount of arguments!

```lua
local events = MD.new()

events:register({"Player"}, function(player)
	print("Just a player")
end)

events:register({"Player", "Part", "number"}, function(player, part, damage)
	print(player.Name .. " damaged " .. part.Name .. " for " .. damage)
end)

events:register({"Player", "Part", "number", "string", "boolean"}, function(p, part, dmg, weapon, crit)
	print("Woah thats a lot of arguments!")
end)

events(player)
events(player, workspace.Enemy, 50)
events(player, workspace.Boss, 100, "Sword", true)
```

---

## Priority System

When multiple patterns match, priority is:
1. **Value matches** (most specific)
2. **Type matches** (medium)
3. **Any matches** (least specific)

```lua
local priority = MD.new()

local chest = Instance.new("Part")
chest.Parent = workspace
chest.Name = "Chest"

local vipPlayer

for _, player in game.Players:GetPlayers() do
	if math.random(1, 2) == 2 then
	player:SetAttribute("IsVIP", true)
		vipPlayer = player
		break
	end
end

priority:register({
	{mode = "value", value = vipPlayer},
	"Part"
}, function(player, part)
	print("VIP player gets special treatment!")
end)

priority:register({"Player", "Part"}, function(player, part)
	print("Regular player")
end)

priority:register({"any", "Part"}, function(anything, part)
	print("Fallback for any entity")
end)

if vipPlayer then
	priority(vipPlayer, chest)
end
priority(player, chest)
```

---

## Practical Example: Combat System

```lua
local damage = MD.new()

damage:setHierarchy("Humanoid", "Instance")

damage:register({"Player", "Humanoid", "number"}, function(attacker, target, amount)
	target.Health -= amount
	print(attacker.Name .. " dealt " .. amount .. " damage!")
end)

damage:register({"Player", "Humanoid", "number", "string"}, function(attacker, target, amount, weapon)
	local multiplier = weapon == "Sword" and 1.5 or 1
	target.Health -= amount * multiplier
	print(attacker.Name .. " dealt " .. (amount * multiplier) .. " with " .. weapon)
end)

damage:register({"NPC", "Player", "number"}, function(npc, player, amount)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health -= amount * 0.5
		print("NPC attacks are weaker!")
	end
end)
```

---

## TL;DR? Examples below

### ROBLOX HIERARCHY
```lua
md:setHierarchy("Part", "BasePart")
md:setHierarchy("MeshPart", "BasePart")
md:setHierarchy("BasePart", "Instance")
```

### COMBAT SYSTEM
```lua
combat:register({"Player", "Enemy", "number"}, dealDamage)
combat:register({"Enemy", "Player", "number"}, takeDamage)
```

### INTERACTION SYSTEM
```lua
interact:register({"Player", "any"}, handleInteraction)
```

### INSTANCES
```lua
doors:register({{mode="value", value=bossRoom}, "Player"}, bossEncounter)
```

---

## Contact

For any questions, DM **eclipysus** on Discord!
