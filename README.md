# Multiple Dispatch Library for Roblox

A simple, yet powerful Multiple Dispatch (MD) library for Roblox that lets you define different function behaviors based on argument types, values, and hierarchies.

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

## Setup

Place all modules inside a folder in `ReplicatedStorage` called `MD`. The folder structure should look like this:

```
ReplicatedStorage
└── MD
	├── MD ← main entry point, require this one
	├── Scoper
	├── Dispatcher
	├── Object
	├── Matcher
	├── Hierarchy
	└── Utils
```

Then in any script:

```lua
local MD = require(game.ReplicatedStorage.MD.MD)
```

---

## Entry Points

There are three ways to create a dispatcher depending on what you need.

### MD.new()
A standalone dispatcher. Nothing can look it up later — you have to pass it around manually. Good for isolated, self-contained systems.

```lua
local dispatch = MD.new()
```

### MD.scope(name)
A named dispatcher. Any script that calls `MD.scope("SameName")` gets back the exact same instance. Good for shared systems across multiple scripts.

```lua
local combat = MD.scope("Combat") -- creates it
local combat = MD.scope("Combat") -- returns the same one
```

If no name is passed, it defaults to a global scope.

### MD.object(name or dispatcher)
Creates an object whose methods are automatically dispatched. Accepts either a scope name or an existing dispatcher.

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
	print(player.Name .. " touched a Part!")
end)

example:register({"Player", "Model"}, function(player, model)
	print(player.Name .. " touched the model: " .. model.Name)
end)

local player = game.Players.LocalPlayer
example(player, workspace.somePart) -- uses __call, works just like a function!
example(player, workspace.someModel)
```

---

## Features

### Hierarchy System

If an argument's type doesn't directly match a registered spec, MD walks up the hierarchy you define until it finds a match.

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

**Step by step for `Part`:**
1. Is `Part == BasePart`? No
2. Get `Part`'s parents → `[BasePart]`
3. Is `BasePart == BasePart`? Yes — execute function!

---

### Named Method Dispatch (Object System)

Register functions under a method name, then call them naturally through an object.

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local scope = MD.scope("Combat")

scope:register("attack", {"Enemy"}, function(enemy)
	print("attack enemy")
end)

scope:register("attack", {"Boss"}, function(boss)
	print("attack boss — special case!")
end)

scope:register("heal", {"number"}, function(amount)
	print("healing for", amount)
end)

local character = MD.object("Combat")

character:attack(enemy) -- routes to "attack" + Enemy
character:attack(boss) -- routes to "attack" + Boss
character:heal(50) -- routes to "heal" + number
```

Named and unnamed registrations are completely separate, so `scope(...)` direct calls still work alongside object method calls.

---

### Value Matching

Match specific values — not just types. Any non-type argument passed as a spec is treated as a value match.

```lua
local keybinds = MD.scope("Keybinds")

keybinds:register({Enum.KeyCode.One}, function(key) print("pressed 1") end)
keybinds:register({Enum.KeyCode.E}, function(key) print("interact") end)
keybinds:register({"EnumItem"}, function(key) print("other key") end) -- fallback

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	keybinds(input.KeyCode)
end)
```

String specs work the same way. If the string is a known Roblox/Lua type it becomes a type spec, otherwise it's treated as a value:

```lua
scope:register({"number"}, func) -- type spec
scope:register({"/die"}, func) -- value spec, matches the string "/die"
```

---

### Any Matching

Use `"any"` or `nil` as a spec to match any argument regardless of type.

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

---

### Variable Arguments

Registrations can have any number of specs. The correct function is chosen based on how many arguments are passed and what they are.

```lua
local events = MD.new()

events:register({"Player"}, function(player)
	print("Just a player")
end)

events:register({"Player", "Part", "number"}, function(player, part, damage)
	print(player.Name .. " damaged " .. part.Name .. " for " .. damage)
end)

events:register({"Player", "Part", "number", "string", "boolean"}, function(p, part, dmg, weapon, crit)
	print("Woah, that's a lot of arguments!")
end)

events(player)
events(player, workspace.Enemy, 50)
events(player, workspace.Boss, 100, "Sword", true)
```

---

## Priority System

When multiple patterns could match the same call, the most specific one wins. Each spec in a matching pattern is scored:

| Spec Mode | Score |
|-----------|-------|
| Value | 3 |
| Type | 2 |
| Any | 1 |

The pattern with the highest total score wins. Value-only patterns are also stored in a fast hash table and checked first, before scoring even runs.

```lua
local priority = MD.new()

priority:register({Enum.KeyCode.E, "Player"}, function(key, player)
	print("E key specifically!") -- score 3+2 = 5, wins
end)

priority:register({"EnumItem", "Player"}, function(key, player)
	print("any key") -- score 2+2 = 4
end)

priority:register({"any", "Player"}, function(key, player)
	print("absolute fallback") -- score 1+2 = 3
end)
```

---

## Practical Example: Combat System

```lua
local MD = require(game.ReplicatedStorage.MD.MD)

local combat = MD.scope("Combat")

combat:setHierarchy("Humanoid", "Instance")

combat:register("attack", {"Humanoid", "number"}, function(target, amount)
	target.Health -= amount
	print("dealt " .. amount .. " damage!")
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

## TL;DR Quick Reference

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
local scope = MD.scope("Events") -- same instance
scope(part, player)
```

---

## Contact

For any questions, DM **eclipysus** on Discord!
