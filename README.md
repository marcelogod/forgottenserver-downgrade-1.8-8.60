<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d0221,40:2d0b6e,70:5b1fa8,100:8b5cf6&height=240&section=header&text=%E2%9A%94%EF%B8%8F%20TFS%201.8%20Downgrade&fontSize=52&fontColor=ffffff&fontAlignY=40&desc=Protocol%208.60%20%7C%20Modern%20Engine%20%7C%20Custom%20Systems&descAlignY=62&descSize=17&animation=fadeIn" />
</p>

<div align="center">

[![Build Status](https://ci.appveyor.com/api/projects/status/github/Mateuzkl/forgottenserver-downgrade?branch=official&svg=true)](https://ci.appveyor.com/project/Mateuzkl/forgottenserver-downgrade)
&nbsp;
[![License](https://img.shields.io/badge/license-GPL--2.0-blue?style=flat-square)](LICENSE)
&nbsp;
[![Commits](https://img.shields.io/badge/commits-~900-6a0dad?style=flat-square)](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/commits)
&nbsp;
[![Wiki](https://img.shields.io/badge/docs-wiki-8b5cf6?style=flat-square&logo=wikipedia&logoColor=white)](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki)

</div>

<br/>

<div align="center">

![Engine](https://img.shields.io/badge/ENGINE-TFS%201.8-7c3aed?style=for-the-badge)
![Protocol](https://img.shields.io/badge/PROTOCOL-8.60-f97316?style=for-the-badge)
![C++](https://img.shields.io/badge/C++-23-00599C?style=for-the-badge&logo=cplusplus&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2B-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-vcpkg-0078D4?style=for-the-badge&logo=windows&logoColor=white)

</div>

<br/>

<div align="center">

> **Developed & Optimized by** [Mateuzkl](https://github.com/Mateuzkl)  
> Based on [Nekiro's TFS 1.5 Downgrades](https://github.com/nekiro/TFS-1.5-Downgrades) · Forked from [MillhioreBT's downgrade](https://github.com/MillhioreBT/forgottenserver-downgrade)  
> **Fully reworked** — all systems, optimizations, and custom features by Mateuzkl

</div>

---

## 📋 Índice

<div align="center">

| 🧬 Core Engine | ⚔️ Combat & RPG | 🌍 World Systems | 🏗️ Infrastructure | 📚 Docs & Support |
|:-:|:-:|:-:|:-:|:-:|
| [ClientID .dat](#-clientid-implementation) | [Forge System](#-forge-system-item-fusion) | [Instance System](#-instance-system) | [Compilation](#️-compilation) | [📖 Full Wiki Docs](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki) |
| [Overview](#-overview) | [Imbuement System](#-imbuement-system) | [Guild Halls](#-guild-halls-system) | [Client Config](#-client-configuration-otcv8--mehah) | [📋 Map Conversion](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki/Map-Conversion-Tutorial-%E2%80%90-ServerID-to-ClientID) |
| [Extended Protocol](#-extended-options--modified-860-cip-clients) | [Reward Boss](#-reward-boss-system) | [House Protection](#️-house-protection-system) | [Linux Tuning](#-linux-server-tuning) | [Contributing](#-contributing--issues) |
| [System Spy](#-system-spy) | [Guild Wars](#️-guild-war-system) | [AutoLoot](#️-autoloot-system) | [Magic Roulette](#-magic-roulette-system) | [Project Status](#-project-status) |
| [Token Protect](#-token-item-protection) | [Harmony (Monk)](#-harmony-system--monk-vocation) | [Offline Training](#-offline-training-system) | | [Downloads](#-downloads--client-updater) |
| | | [Live Cast](#-live-cast-system) | | [Donations](#-support-the-project) |
| | | [Zones System](#️-zones-system) | | |

</div>

---

## 🧬 ClientID Implementation

<div align="center">

| ✅ ClientID Only | ✅ Full .dat System | ✅ No Conversion Layer |
|:-:|:-:|:-:|
| No ServerID — Items, maps (OTBM), Lua scripts and DB all use ClientID directly | Reads item definitions from the client's `.dat` file — like Canary and Crystal Server | No ServerID/ClientID mapping — the ID you see in the client is the same everywhere |

</div>

This eliminates the traditional ServerID/ClientID mismatch, making content creation and debugging significantly simpler.

> 🗺️ **To edit maps compatible with this ClientID system, use the modified RME:**  
> **[⬇️ Download RME-CLIENTID](https://github.com/Mateuzkl/RME-CLIENTID)**

### 📚 Map Tutorials

| Tutorial | Description |
|----------|-------------|
| [📋 ServerID → ClientID Conversion](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki/Map-Conversion-Tutorial-%E2%80%90-ServerID-to-ClientID) | Convert standard TFS maps to ClientID format |
| [🗺️ Import Canary/Crystal Maps](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki/Importing-Canary-Crystal-Maps-to-RME-8.60) | Downgrade and import modern server maps |
| [🇧🇷 Importar Mapas Canary/Crystal](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/wiki/%F0%9F%97%BA%EF%B8%8F-Importando-Mapas-Canary-Crystal-para-RME-8.60) | Tutorial em português |

---

## 🚀 Overview

This is a **custom modified version** of The Forgotten Server, downgraded to protocol **8.60** but running on the modern **TFS 1.8** engine. It includes numerous exclusive systems and improvements not found in any standard TFS fork.

<div align="center">

| 🔢 ~900 Commits | 🧩 13+ Custom Systems |
|:-:|:-:|
| Actively maintained | Fully integrated in C++ |

</div>

---

## 🎮 Systems & Features

### 🛡️ AutoLoot System

<details>
<summary><b>Click to expand</b></summary>

- **Fully Integrated**: Built directly into the source for maximum performance — no Lua overhead.
- **Bank Integration**: Automatically deposits gold if "AutoMoney" mode is enabled.

| Command | Description |
|---------|-------------|
| `!autoloot` | Opens the GUI management window |
| `!autoloot on/off` | Quickly toggle the system |
| `!autoloot clear` | Clear your entire loot list |

</details>

---

### ⚔️ Guild War System

<details>
<summary><b>Click to expand</b></summary>

- **Real Guild Wars**: Fully working war system with live emblems.
- **Emblems**: Ally, Member, and Enemy emblems update in real-time.

| Command | Description |
|---------|-------------|
| `/war invite, guildname` | Invite a guild to war |
| `/war accept, guildname` | Accept a war declaration |

</details>

---


### 🏆 Reward Boss System

<details>
<summary><b>Click to expand</b></summary>

- **Tibia-like Rewards**: Global Tibia style boss reward system.
- **Reward Chests**: Stored in reward containers (ID: `21518` / `21584`).
- Configurable reward rates via `config manager`.

| Tracking | Description |
|----------|-------------|
| Damage Done | Tracks your DPS contribution |
| Damage Taken | Tracks survivability contribution |
| Healing Done | Tracks support contribution |
| **Fair Distribution** | Loot distributed by total contribution score |

</details>

---

### 💤 Offline Training System

<details>
<summary><b>Click to expand</b></summary>

- Train skills while offline using beds — **Premium required**.
- **Usage**: Simply click on the bed to start training.
- Automatically calculates gain based on logout duration (**Max 12h**).
- **Configuration**: Efficiency and vocation rates in `config.lua`.

| Trainable Skills |
|:-:|
| Sword · Axe · Club · Distance · Shielding · Magic Level |

</details>

---

### 🏰 Guild Halls System

<details>
<summary><b>Click to expand</b></summary>

- **Guild Leaders** can purchase special Guild Halls paid via Guild Bank balance.
- **Features**: Supports all house features — doors, beds, and protection zones.

| Command | Access | Description |
|---------|--------|-------------|
| `!buyhouse` | Leader / Vice-Leader | Purchase a guild hall |
| `!leavehouse` | Leader | Abandon the hall |

</details>

---

### 🛡️ House Protection System

<details>
<summary><b>Click to expand</b></summary>

- **Per-house control**: Owners can toggle protection state independently per house.
- **Secure**: When enabled, ONLY owner and listed guests can move items.
- Door messages show real ownership info.

| Command | Description |
|---------|-------------|
| `!protecthouse on/off` | Toggle protection state |
| `!houseguest add <name>` | Add a guest to the safe list |
| `!houseguest remove <name>` | Remove a guest |
| `!houseguest list` | View current guest list |

</details>

---

### ⚡ Improved Decay System

<details>
<summary><b>Click to expand</b></summary>

Enhanced decay system for better server performance. Optimized item decay processing and state management — significantly reduces CPU usage on populated servers.

</details>

---

### 📺 Live Cast System

<details>
<summary><b>Click to expand</b></summary>

- Stream your gameplay with `!cast` for others to watch live.
- **Bonus**: Configurable EXP bonus for active casters.
- **Spectators**: Can chat in the dedicated Live Cast channel.

| Command | Access | Description |
|---------|--------|-------------|
| `!cast` | Caster | Start/stop broadcasting |
| `/spectators` | Caster | List current spectators |
| `/kick <name>` | Caster | Kick a spectator |
| `/mute <name>` | Caster | Mute a spectator |
| `/ban <name>` | Caster | Ban a spectator |

</details>

---

### 🔒 Token Item Protection

<details>
<summary><b>Click to expand</b></summary>

Prevent character theft and account hacks with the **Token Protection System**. When enabled, your items are locked to your character, making it impossible for unauthorized users to move them out of your inventory or houses.

**Key Features:**
- **Anti-Theft**: Prevents moving items from your character or house to other locations.
- **Smart Filtering**: You can still move "trash" items like Gold, Worms, Food, and Flowers.
- **Normal Gameplay**: Full support for swapping items, moving to Depot, and organizing backpacks.
- **Lending Safety**: Safely lend your character to friends without risk of losing gear.

| Command | Description |
|---------|-------------|
| `!token set, YOUR_TOKEN` | Set your secret security token (only while disabled) |
| `!token on` | Enable the protection system |
| `!token off, YOUR_TOKEN` | Disable protection using your secret token |

> [!IMPORTANT]
> Keep your token secret! It is only required to **disable** the protection. You cannot set a new token while protection is active.

</details>

---

### 👁️ System Spy

<details>
<summary><b>Click to expand</b></summary>

The **System Spy** is a powerful administrative tool that allows GODs and Admins to silently observe players in real-time without their knowledge.

**Functionality:**
- **Silently Observe**: GM protocols are attached to the target's session. The target receives no notification.
- **Viewport Mirroring**: The GM's client automatically redirects to the target's position, showing all tiles and creatures around the target.
- **Inventory & Containers**: Real-time mirroring of the target's inventory slots and all open containers/backpacks.
- **Auto-Sync**: The GM's view stays perfectly in sync with the target's movements.

| Command | Permission | Description |
|---------|------------|-------------|
| `/spy <name>` | GOD / Admin | Start spying on the target player |
| `/spyinv <name>` | GOD / Admin | View the target player's current inventory slots and open containers |
| `/unspy` | GOD / Admin | Stop spying or close the spy inventory view and return to your own state |

> [!CAUTION]
> This system is designed for server administration and debugging. Improper use may affect the gameplay experience of others.

</details>

---

### 🎰 Magic Roulette System

<details>
<summary><b>Click to expand</b></summary>

An advanced, interactive **Magic Roulette** system with rich visual effects and animations. Players can test their luck at roulette stations for a chance to win rare rewards.

![Magic Roulette](https://user-images.githubusercontent.com/40324910/236821618-63cb56a4-3003-4156-a05f-02375649fe55.gif)

**Features:**
- **Interactive UI**: Lever-activated roulette with smooth visual animations on the map.
- **Customizable Rewards**: Configure items, counts, and drop chances (including rare/legendary items).
- **Visual Feedback**: Real-time map animations and effects during the spin.
- **Database Tracking**: All plays are recorded in the database for auditing and statistics.
- **Versatile Modes**: Supports both horizontal and vertical layout configurations.

> **Configuration**: Can be easily customized in `data/scripts/magic-roulette-master/configroulette.lua`.

</details>

---

### 🔥 Forge System (Item Fusion)

<details>
<summary><b>Click to expand</b></summary>

![Forge System](forge.gif)

Fuse two identical items — one is consumed, the other gains **+1 Tier**. Tier is capped by item classification.

### 📖 How to Use
1. **Combine Items**: Place two identical items of the same Tier into the Forge slots.
2. **Materials**: Ensure you have enough **Forge Dust** and **Silver Tokens**. High tiers (T5+) require **Exalted Cores**.
3. **Fusion**: Click the fusion button. If successful, your item gains **+1 Tier**.
4. **Failure**: On failure, one item is destroyed and the other remains at its current Tier.
5. **Limits**: Tier upgrades are capped by the item's **Classification** (e.g., Class 1, Class 2).

---

| Tier | Success Rate | Extra Materials |
|:----:|:---:|:-:|
| T0 → T1 | 50% | — |
| T1 → T2 | 40% | — |
| T2 → T3 | 30% | — |
| T3 → T4 | 25% | — |
| T4 → T5 | 20% | — |
| T5 → T6 | 15% | Exalted Core required |
| T6 → T7 | 10% | Exalted Core required |
| T7 → T8 | 8% | Exalted Core required |
| T8 → T9 | 5% | Exalted Core required |

**Materials**: Forge Dust · Silver Tokens · Exalted Cores (T5+)  
**On Success**: Upgraded item placed inside an Exaltation Chest and delivered to inventory.

| Command | Description |
|---------|-------------|
| `/forge info` | Show forge info |
| `/forge dust` | Check your Forge Dust |
| `/forge silver` | Check your Silver Tokens |

</details>

---

### 🧿 Imbuement System

<details>
<summary><b>Click to expand</b></summary>

The system supports two distinct methods for applying imbuements. You can choose whichever fits your needs best:

#### 📜 Method 1: Imbuement Scrolls
Directly apply imbuements using scrolls. This is the fastest way to get your gear upgraded.

![Scroll Method](imbuments_scroll.gif)

#### 🧪 Method 2: Raw Materials & Etching
Craft imbuements from raw creature products and materials using the **Etcher** tool at the workbench.

![Raw Materials Method](imbuments_items.gif)

---

- **Workbench**: 4-slot station — 1 equipment + up to 3 slots for scrolls or raw materials.
- **Owner Lock**: To prevent theft, only the item's owner can apply imbuements.
- **Tiers**: Flawed → Intricate → **Powerful**

| Available Tiers | Types Available |
|:-----:|:-:|
| 3 Stages | **27 types**: Skill boosts, Magic Level, Life/Mana Leech, Critical Hit, Elemental Damage & Protection, Speed, Capacity |

</details>

---

### 🏰 Instance System

<details>
<summary><b>Click to expand</b></summary>

Create **private dungeon instances** — monsters, effects, and items are only visible to players in the same instance.

**Lua API:**
```lua
player:setInstanceId(id)
Game.registerInstanceArea(area)
Game.createMonster(name, pos, extended, force, master, instanceId)
```

**C++ Core**: Spectator filtering, item visibility, and interaction checks all respect instance boundaries.

> **Use Cases**: Solo/party dungeons · Boss rooms · Quests — without interfering with the main world.

</details>

---

### 🗺️ Zones System

<details>
<summary><b>Click to expand</b></summary>

Allows server administrators to create custom geographical **Zones** by assigning a unique ID to a group of map coordinates. This is perfect for custom map events, localized effects, or restricted areas.

**Key Features:**
- **XML Configured**: Easily define zones in `data/world/world-zones/1.xml` by mapping an ID to `X, Y, Z` coordinates.
- **Rich Lua API**: Full integration in Lua via the `Zone` class to query entities inside a zone:
  - `zone:getCreatures([type])` / `zone:getCreatureCount([type])`
  - `zone:getItems([itemId])` / `zone:getItemCount([itemId])`
  - `zone:getGrounds()`
  - `zone:getTiles([flags])` / `zone:getTileCount([flags])`
- **Dynamic Creation**: Build zones on the fly using `Zone(id, positions)`.
- **Event Callbacks**: Triggers `Creature:onChangeZone(fromZone, toZone)` in Lua whenever a creature enters or leaves a configured zone.

> **Use Cases**: Safe zones, PvP arenas, custom events, or territory control without needing complex `isInArea` checks manually!

</details>

---

### 🧘 Harmony System — Monk Vocation

<details>
<summary><b>Click to expand</b></summary>

Exclusive to **Monks** (vocations 9–10). A resource management system where you accumulate **Harmony points (0-5)** by hitting enemies with **Builder Spells**, then spend them with powerful **Spender Spells**.

#### 📊 Core Mechanics

- **Gain Harmony**: Hit enemies with any attack → +1 point (max 5)
- **Spend Harmony**: Cast spells marked with `spell:harmony(true)` → consumes ALL points
- **Bonus Scaling**: More points = stronger spell effects

#### 🎯 Harmony Bonus Table

| Points | Base Bonus | With Virtue of Harmony |
|:------:|:----------:|:----------------------:|
| 0 | 0% | 0% |
| 1 | +15% | +25% |
| 2 | +30% | +55% |
| 3 | +60% | +100% |
| 4 | +120% | +200% |
| 5 | +240% | +400% |

#### ⚡ Virtues — Modify Harmony Bonuses

Cast a Virtue spell to change how your Harmony points scale:

| Virtue | Effect | Spell |
|--------|--------|-------|
| 🧘 **Harmony** | Doubles the bonus table above | `utori virtu` (Virtue of Harmony) |
| ⚖️ **Justice** | *Planned* — Will increase damage output | `utori justi` (Virtue of Justice) |
| 🛡️ **Sustain** | *Planned* — Will increase defense | `utori sana` (Virtue of Sustain) |

> **Note**: Justice and Sustain virtues are defined in code but not yet implemented with combat effects.

#### 🌟 Serene State

- **Effect**: Doubles ALL Virtue bonuses (stacks multiplicatively)
- **Activation**: Cast `Focus Serenity` or activate `Avatar of Balance`
- **Duration**: Temporary buff with cooldown

#### 🔮 Avatar of Balance

Ultimate transformation that enhances all Monk systems:
- Sets Harmony to 5/5 instantly
- Activates Serene State
- +50% bonus to all Harmony effects
- Clears all spell cooldowns
- Duration: 30 seconds

#### 📝 Commands

| Command | Description |
|---------|-------------|
| `!harmony` | View current Harmony points, active Virtue, Serene state, and bonus % |

#### 🎮 Spell Types

**Builder Spells** (gain Harmony):
- Double Jab, Swift Jab, Flurry of Blows, Forceful Uppercut, Mystic Repulse, Chained Penance

**Spender Spells** (consume Harmony):
- Tiger Clash, Greater Tiger Clash, Sweeping Takedown, Devastating Knockout, Spiritual Outburst, Mass Spirit Mend

**Example**: Mass Spirit Mend healing scales with Harmony:
```lua
local multiplier = 1 + (harmony * 0.6)
-- At 5 Harmony: 1 + (5 * 0.6) = 4x healing!
```

</details>

---

## 🛠️ Compilation

### 🐧 Ubuntu 22.04 / 24.04

> [!IMPORTANT]
> Requires **Boost 1.75+** and **Lua 5.4**
> - **Ubuntu 24.04** ✅ Recommended — comes with all required versions
> - **Ubuntu 22.04** ⚠️ May need manual Boost update (default is 1.74)

#### Step 1 — Install dependencies

```bash
sudo apt update
sudo apt install -y \
  git cmake build-essential pkg-config \
  liblua5.4-dev libmysqlclient-dev \
  libboost-system-dev libboost-iostreams-dev libboost-filesystem-dev \
  libboost-locale-dev libboost-regex-dev libboost-json-dev \
  libpugixml-dev libfmt-dev libssl-dev libspdlog-dev libmimalloc-dev \
  libabsl-dev
```

#### Step 2 — Install simdutf manually (Linux only)

> **Note:** `simdutf` is not available as a ready-to-use development package via `apt` on Ubuntu 22.04+. You must install it manually into `$HOME/.local`:
>
> ⚠️ **Windows users**: Skip this step — `simdutf` is automatically installed via vcpkg (see `vcpkg.json`)

```bash
cd ~
git clone https://github.com/simdutf/simdutf.git
cd simdutf
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build -- -j"$(nproc)"
cmake --install build
```

#### Step 3 — Clone & Compile (Release Mode - Faster Startup)

> **Note:** We use `Release` mode building as the default because it makes the server start up and load the map significantly faster.

```bash
git clone https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60
cd forgottenserver-downgrade-1.8-8.60

rm -rf build-release
mkdir build-release && cd build-release

cmake -DCMAKE_BUILD_TYPE=Release \
      -DDISABLE_STATS=1 \
      -DENABLE_SLOW_TASK_DETECTION=OFF \
      -DUSE_MIMALLOC=ON \
      ..

cmake --build . -- -j"$(nproc)"
```

> **Note:** CMake automatically detects `simdutf` installed in `$HOME/.local` (no need to specify `-Dsimdutf_DIR`). If you installed it elsewhere, add: `-Dsimdutf_DIR=/your/path/lib/cmake/simdutf`

| CMake Flag | Effect |
|------------|--------|
| `-DCMAKE_BUILD_TYPE=Release` | Enables `-O3 -march=native -flto` — maximum speed |
| `-DDISABLE_STATS=1` | Removes runtime stats collection overhead |
| `-DENABLE_SLOW_TASK_DETECTION=OFF` | Removes per-task timing overhead |
| `-DUSE_MIMALLOC=ON` | Microsoft's mimalloc allocator — faster than glibc malloc |

**Alternative — run mimalloc without recompiling:**
```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libmimalloc.so ./tfs
```

#### 🔧 Linux Server Tuning

```bash
# Maximum CPU performance
sudo cpupower frequency-set -g performance

# Higher process priority
sudo nice -n -10 ./tfs
```

---

### 🪟 Windows

#### Install vcpkg

```bash
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg.exe integrate install
```

#### Build with Visual Studio

Use **Visual Studio 2022** (or newer), select backend (OpenGL, DirectX), platform (x86, x64) and just build. All required libraries will be automatically installed for you.

> 📖 See the full [Windows Compilation Wiki Guide](https://github.com/MillhioreBT/forgottenserver-downgrade/wiki/Compiling-on-Windows-(vcpkg))

**Note:** All dependencies including `simdutf` are automatically installed via vcpkg (see `vcpkg.json`). No manual installation required.

---

## 📦 Client Configuration (OTCv8 / Mehah)

**1. Update `modules/game_features/game_features.lua`:**

```lua
if(version >= 860) then
    g_game.enableFeature(GameAttackSeq)
    g_game.enableFeature(GameBot)
    g_game.enableFeature(GameExtendedOpcode)
    g_game.enableFeature(GameSkillsBase)
    g_game.enableFeature(GamePlayerMounts)
    g_game.enableFeature(GameMagicEffectU16)
    g_game.enableFeature(GameDistanceEffectU16)
    g_game.enableFeature(GameDoubleHealth)
    g_game.enableFeature(GameOfflineTrainingTime)
    g_game.enableFeature(GameDoubleSkills)
    g_game.enableFeature(GameBaseSkillU16)
    g_game.enableFeature(GameAdditionalSkills)
    g_game.enableFeature(GameIdleAnimations)
    g_game.enableFeature(GameEnhancedAnimations)
    g_game.enableFeature(GameSpritesU32)
    g_game.enableFeature(GameExtendedClientPing)
    g_game.enableFeature(GameDoublePlayerGoodsMoney)
    g_game.enableFeature(GameCreatureIcons)
end
```

**2. Extended Sprites (`GameSpritesU32`)**
- Download: [Octv8--Classic-8.6](https://github.com/Mateuzkl/Octv8--Classic-8.6)
- Extract `.spr` and `.dat` to your OTCv8 directory

**3. CIP Client with Mounts (DLL)**
- Download: [Client 8.60 + DLL Mount](https://github.com/Mateuzkl/Client-cip-8.60-with-DLL-Mount)

---

## 🎮 Extended Options — Modified 8.60 CIP Clients

DLL patches that extend the old Tibia 8.60 client beyond its original protocol limits:

| DLL Patch | Status | Extends |
|-----------|:------:|---------|
| `__MAGIC_EFFECTS_U16__` | ✅ | Magic effects: **255 → 65535** (uint16) |
| `__DISTANCE_SHOOT_U16__` | ✅ | Projectile effects: **255 → 65535** (uint16) |
| `__PLAYER_HEALTH_U32__` | ✅ | Player HP: **65535 → 4.2 billion** (uint32) |
| `__PLAYER_MANA_U32__` | ✅ | Player Mana: **65535 → 4.2 billion** (uint32) |
| `__PLAYER_SKILLS_U16__` | ⏳ Pending | Skill levels up to 65535 (in development) |
| **Outfit Limit Changer** | ✅ | Outfits: **255 → 65535+** (uint16 count) |

---

## 🐛 Contributing & Issues

The base is **stable** and all systems are fully working. Found a bug? You're very welcome to help:

- 🐞 **Open an Issue** → [GitHub Issues](https://github.com/Mateuzkl/forgottenserver-downgrade-1.8-8.60/issues)  
  Include: description · steps to reproduce · relevant logs or Valgrind output
- 🔧 **Submit a Pull Request** → Surgical, minimal patches preferred — change only what is necessary

> Any contribution is appreciated. This server is optimized, actively maintained, and packed with exclusive systems. Community involvement helps keep it that way.

*Maintained by [Mateuzkl](https://github.com/Mateuzkl)*

---

## 📢 Project Status

<div align="center">

| Metric | Value |
|:------:|:-----:|
| 📦 Commits | **~900** |
| 🧩 Custom Systems | **13+** |
| 🔧 Status | **Stable & Active** |

</div>

---

## 🤝 Support the Project

If you enjoy using this server or benefit from the work, any support is deeply appreciated. Donations help fund continued development and motivate new system releases.

<div align="center">

**💜 PIX Key (Chave Aleatória)**

```
f8761afe-5581-417d-afc8-08cac410a1b0
```

*Thank you to everyone who contributes — code, bug reports, or donations.*

</div>

---

## 📥 Downloads & Client Updater

### Manual Download (AppVeyor Artifacts)

1. Open the [AppVeyor Project Page](https://ci.appveyor.com/project/Mateuzkl/forgottenserver-downgrade-1-7-8-60)
2. Click the latest **Job** → go to the **Artifacts** tab
3. Download the `.zip` or `.7z` with the executable and DLLs
4. Extract into your client folder, replacing existing files

### 🔄 Automated Client Updater

Update your CipSoft client, executables and DLLs automatically with just a few clicks:

> 📖 **[Client Updater Tutorial — Mateuzkl/Client_Mout_Updater](https://github.com/Mateuzkl/Client_Mout_Updater)**

---

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:8b5cf6,50:5b1fa8,100:0d0221&height=140&section=footer&text=Made%20with%20%F0%9F%92%9C%20by%20Mateuzkl&fontSize=18&fontColor=ffffff&fontAlignY=65" />
</p>
