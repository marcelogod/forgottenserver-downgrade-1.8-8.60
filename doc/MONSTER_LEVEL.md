# Monster Level System

## Overview

The Monster Level System assigns a random level to each monster upon spawning, based on per-monster min/max level ranges defined in the monster's Lua definition. Based on the monster's level, the system applies:

- A **skull** visible to players (white, red, or black) indicating the monster's tier.
- **Bonus multipliers** for damage, speed, and health proportional to the monster's level.
- The level is displayed in the creature name: `"Hero [15]"`.

The entire system can be toggled **ON/OFF** via `config.lua`.

## Quick Start

### 1. Enable the system
In `config.lua`:
```lua
monsterLevelEnabled = true
```

### 2. Configure skull ranges and bonuses
In `data/scripts/monsterlevel/config.lua`:
```lua
setMonsterLevelSkullRange(SKULL_WHITE, 1, 100)
setMonsterLevelSkullRange(SKULL_RED, 100, 500)
setMonsterLevelSkullRange(SKULL_BLACK, 500, 2000)
setMonsterLevelBonus("damage", 0.01)
setMonsterLevelBonus("speed", 0.01)
setMonsterLevelBonus("health", 0.02)
```

### 3. Add level to monster definitions
In any monster `.lua` file (e.g., `data/monsters/humans/hero.lua`):
```lua
monster.level = {min = 1, max = 50}
```

## Configuration Reference

### `config.lua`
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `monsterLevelEnabled` | boolean | `false` | Global toggle for the monster level system |

### `data/scripts/monsterlevel/config.lua`
| Lua Function | Parameters | Description |
|-------------|------------|-------------|
| `setMonsterLevelSkullRange(skull, min, max)` | `skull`: Skull constant (`SKULL_WHITE`, `SKULL_RED`, `SKULL_BLACK`) <br> `min`: Minimum level (inclusive) <br> `max`: Maximum level (inclusive) | Sets the skull assigned to monsters within the given level range |
| `setMonsterLevelBonus(type, value)` | `type`: `"damage"`, `"speed"`, or `"health"` <br> `value`: Multiplier per level (float) | Sets the bonus multiplier. Example: `0.01` = 1% increase per level |

### Monster Definition (.lua)
| Field | Type | Description |
|-------|------|-------------|
| `monster.level.min` | integer | Minimum level this monster can spawn with |
| `monster.level.max` | integer | Maximum level this monster can spawn with |

**Note:** Both `min` and `max` must be set, and `max > min`. Levels less than or equal to 0 disable the system for that monster type.

## Lua API

### MonsterType Methods
| Method | Description |
|--------|-------------|
| `monsterType:minLevel()` / `monsterType:minLevel(value)` | Get/set minimum level for this monster type |
| `monsterType:maxLevel()` / `monsterType:maxLevel(value)` | Get/set maximum level for this monster type |

### Monster Methods
| Method | Description |
|--------|-------------|
| `monster:getLevel()` | Returns the current monster's level |

### Example: Get a spawned monster's level
```lua
local level = monster:getLevel()
print("Monster level:", level)
```

## Bonus Calculation

When a monster spawns with level `L`:

| Bonus | Formula |
|-------|---------|
| Health | `health = health + round(health * bonusHP * L)` |
| Max Health | `healthMax = healthMax + round(healthMax * bonusHP * L)` |
| Speed | `baseSpeed = baseSpeed + round(baseSpeed * bonusSpeed * L)` |
| Damage | `damage = damage + round(damage * bonusDmg * L)` |

All values are applied *after* the monster's base stats but *before* `std::abs()` on negative damage values.

## Skull Assignment

Monsters receive a skull based on their randomized level and the configured ranges. If a level falls outside all configured ranges, no skull is shown (`SKULL_NONE`).

### Default Skull Ranges
| Skull | Level Range |
|-------|-------------|
| White | 1 – 100 |
| Red | 100 – 500 |
| Black | 500 – 2000 |

> **Note:** Ranges are **inclusive** on both ends. Adjust boundaries carefully to avoid overlap.

## C++ Architecture

### Key Classes and Files

| File | Purpose |
|------|---------|
| `src/monster.h` | `Monster` class — `getLevel()` method, modified `getDescription()` |
| `src/monster.cpp` | `Monster` constructor applies level/skull/bonuses; `monsterlevel` namespace |
| `src/monsters.h` | `MonsterType::MonsterInfo` — `minLevel`, `maxLevel` fields |
| `src/creature.h` | `Creature` base class — `int32_t level` field |
| `src/configmanager.h` | `MONSTER_LEVEL_ENABLED` enum value |
| `src/configmanager.cpp` | Loads `monsterLevelEnabled` from `config.lua` |
| `src/game.cpp` | `combatChangeHealth()` and `combatChangeMana()` apply damage bonus |
| `src/protocolgame.cpp` | `AddCreature()` sends name with level suffix |
| `src/luamonstertype.cpp` | `MonsterType:minLevel()`, `MonsterType:maxLevel()` Lua bindings |
| `src/luamonster.cpp` | `Monster:getLevel()` Lua binding |
| `src/luascript.cpp` | `setMonsterLevelSkullRange()`, `setMonsterLevelBonus()` global Lua functions |

### `monsterlevel` Namespace
```cpp
namespace monsterlevel {
    void setSkullRange(Skulls_t skull, int32_t minLevel, int32_t maxLevel);
    void setBonus(const std::string& type, float value);
    Skulls_t getSkullByLevel(int32_t level);
    float getBonusDamage();
    float getBonusSpeed();
    float getBonusHealth();
}
```

### Smart Pointers
- `MonsterType` instances are stored as `std::shared_ptr<MonsterType>` in `Monsters::monsters`
- `Monster` instances are created as `std::unique_ptr<Monster>` via `Monster::createMonster()`
- The `MonsterLevelConfig` uses value semantics (no manual memory management needed)

## Example Monster

```lua
local mType = Game.createMonsterType("Elite Hero")
local monster = {}

monster.name = "Elite Hero"
monster.description = "an elite hero"
monster.experience = 2500
monster.outfit = { lookType = 73, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookAddons = 3 }
monster.health = 3000
monster.maxHealth = 3000
monster.speed = 160
monster.level = {min = 50, max = 150}  -- Monster Level System

-- ... rest of monster definition ...

mType:register(monster)
```

## License
This system follows the same license as the base project (GPL-2.0).
