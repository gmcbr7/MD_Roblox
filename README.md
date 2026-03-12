# Multiple Dispatch Library for Roblox

A Multiple Dispatch (MD) library for Roblox that lets you define different function behaviors depending on argument types, values, or hierarchies.

Created by: GMC (eclipysus on Discord)

I've been coding for about 6 months, so this is an early version. I plan to revisit and improve parts of it later once I have more experience. Feedback is welcome.

Special thanks to my brother for introducing me to the concept and recommending books about languages like Common Lisp that use multiple dispatch.

---

## What is Multiple Dispatch?

Normally you end up writing many `if` checks to handle different argument combinations. Multiple dispatch handles that automatically by choosing the correct function based on the arguments passed.

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

## Setup

Place all modules inside a folder in `ReplicatedStorage` called `MD`.

Structure:

```
ReplicatedStorage
└── MD
    ├── MD (main entry point)
    ├── Scoper
    ├── Dispatcher
    ├── Object
    ├── Matcher
    ├── Hierarchy
    └── Utils
```

Then require it in a script:

```lua
local MD = require(game.ReplicatedStorage.MD.MD)
```

---

## Entry Points

There are three ways to create a dispatcher depending on how you want to use it.

### MD.new()

Creates a standalone dispatcher. It isn't globally accessible unless you pass the reference around.

Useful for isolated systems.

```lua
local dispatch = MD.new()
```

### MD.scope(name)

Creates or retrieves a named dispatcher. Calling `MD.scope` with the same name returns the same instance.

Useful when multiple scripts need access to the same dispatcher.

```lua
local combat = MD.scope("Combat") -- creates it
local combat = MD.scope("Combat") -- returns the same one
```

If no name is provided, it defaults to a global scope.

### MD.object(name or dispatcher)

Creates an object whose methods use dispatch internally.

```lua
local character = MD.object("Combat")

-- or

local character = MD.object(myDispatcher)
```

---

## Basic Usage

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local example = MD.new()

example:register({"Player", "Part"}, function(player, part)
	print(player.Name .. " touched a Part")
end)

example:register({"Player", "Model"}, function(player, model)
	print(player.Name .. " touched the model: " .. model.Name)
end)

local player = game.Players.LocalPlayer

example(player, workspace.somePart)
example(player, workspace.someModel)
```

Dispatchers implement `__call`, so they can be used like normal functions.

---

## Features

### Hierarchy System

If an argument type doesn't match directly, MD checks the hierarchy you define until it finds a match.

```lua
local combat = MD.new()

combat:setHierarchy("Part", "BasePart")
combat:setHierarchy("MeshPart", "BasePart")
combat:setHierarchy("WedgePart", "BasePart")

combat:register({"Player", "BasePart"}, function(player, part)
	print("Works with any BasePart child")
end)

combat(player, workspace.Part)
combat(player, workspace.MeshPart)
combat(player, workspace.WedgePart)
```

Example resolution for `Part`:

1. Check `Part == BasePart`
2. Look up parents of `Part`
3. `BasePart` matches → execute function

---

### Named Method Dispatch (Object System)

You can register functions under a method name and call them through an object.

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local scope = MD.scope("Combat")

scope:register("attack", {"Enemy"}, function(enemy)
	print("attack enemy")
end)

scope:register("attack", {"Boss"}, function(boss)
	print("attack boss (special case)")
end)

scope:register("heal", {"number"}, function(amount)
	print("healing for", amount)
end)

local character = MD.object("Combat")

character:attack(enemy)
character:attack(boss)
character:heal(50)
```

Named registrations and direct dispatcher calls are separate, so both styles can exist together.

---

### Value Matching

Specs can match exact values instead of types.

```lua
local keybinds = MD.scope("Keybinds")

keybinds:register({Enum.KeyCode.One}, function(key)
	print("pressed 1")
end)

keybinds:register({Enum.KeyCode.E}, function(key)
	print("interact")
end)

keybinds:register({"EnumItem"}, function(key)
	print("other key")
end)
```

Example usage:

```lua
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	keybinds(input.KeyCode)
end)
```

Strings behave as follows:

```lua
scope:register({"number"}, func) -- type match
scope:register({"/die"}, func) -- value match
```

---

### Any Matching

Use `"any"` or `nil` to match any argument.

```lua
local inventory = MD.new()

inventory:register({"Player", "any"}, function(player, item)
	print(player.Name .. " picked up an item")
end)

inventory(player, workspace.Sword)
inventory(player, workspace.Potion)
inventory(player, 12345)
inventory(player, "anything")
```

---

### Variable Arguments

Functions can have different argument counts.

```lua
local events = MD.new()

events:register({"Player"}, function(player)
	print("Just a player")
end)

events:register({"Player", "Part", "number"}, function(player, part, damage)
	print(player.Name .. " damaged " .. part.Name .. " for " .. damage)
end)

events:register({"Player", "Part", "number", "string", "boolean"}, function(p, part, dmg, weapon, crit)
	print("Many arguments")
end)

events(player)
events(player, workspace.Enemy, 50)
events(player, workspace.Boss, 100, "Sword", true)
```

---

## Priority System

If multiple patterns match, the most specific one wins.

Scoring system:

| Spec Mode | Score |
|-----------|-------|
| Value		| 3		|
| Type 		| 2		|
| Any 		| 1		|

Example:

```lua
local priority = MD.new()

priority:register({Enum.KeyCode.E, "Player"}, function(key, player)
	print("E key specifically")
end)

priority:register({"EnumItem", "Player"}, function(key, player)
	print("any key")
end)

priority:register({"any", "Player"}, function(key, player)
	print("fallback")
end)
```

Higher score patterns are chosen first.

---

## Practical Example: Combat System

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local combat = MD.scope("Combat")

combat:setHierarchy("Humanoid", "Instance")

combat:register("attack", {"Humanoid", "number"}, function(target, amount)
	target.Health -= amount
	print("dealt " .. amount .. " damage")
end)

combat:register("attack", {"Humanoid", "number", "string"}, function(target, amount, weapon)
	local multiplier = weapon == "Sword" and 1.5 or 1
	target.Health -= amount * multiplier

	print("dealt " .. (amount * multiplier) .. " with " .. weapon)
end)

local character = MD.object("Combat")

character:attack(enemy.Humanoid, 20)
character:attack(enemy.Humanoid, 20, "Sword")
```

---

## Practical Example: Chat Commands

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local player = game.Players.LocalPlayer
local commands = MD.scope("Commands")

commands:register({"/die", "any"}, function(message, plr)
	plr.Character.Humanoid.Health = 0
end)

commands:register({"/heal", "any"}, function(message, plr)
	plr.Character.Humanoid.Health = 100
end)

player.Chatted:Connect(function(message)
	commands(message, player)
end)
```

---

## Quick Reference

### Setup hierarchy

```lua
md:setHierarchy("Part", "BasePart")
md:setHierarchy("MeshPart", "BasePart")
md:setHierarchy("BasePart", "Instance")
```

### Named method dispatch

```lua
scope:register("attack", {"Enemy", "number"}, dealDamage)
scope:register("defend", {"Shield"}, block)

local character = MD.object("Combat")

character:attack(enemy, 50)
character:defend(shield)
```

### Value matching

```lua
scope:register({Enum.KeyCode.E}, onInteract)
scope:register({"/die", "any"}, onDie)
scope:register({{mode = "value", value = workspace.BossRoom}, "Player"}, bossEncounter)
```

### Shared scope across scripts

```lua
-- Script A
local scope = MD.scope("Events")
scope:register({"Part", "Player"}, onTouch)

-- Script B
local scope = MD.scope("Events")
scope(part, player)
```

---

## Contact

Discord: **eclipysus**
