# Classic Dungeon Raid — Rojo Scaffold (2007 Studs PvE Co-op)

A strict **2007 classic-studs** Roblox PvE dungeon/raid co-op scaffold managed with [Rojo](https://rojo.space).

## Requirements
- Rojo CLI ≥ 7.x (`rojo --version`)
- The Rojo Studio plugin
- Roblox Studio with this place saved (empty is fine — Rojo builds the tree)

## Folder Structure

```
default.project.json          # Rojo sync map (see below)
src/
  server/                     # -> ServerScriptService
    ServerBootstrap.server.lua   # lighting/sky/R6 lock + service wiring
    DungeonService.lua           # waves, boss, run lifecycle
    ReviveService.lua            # per-run revive cap + dev-product tokens
    MonetizationService.lua      # idempotent ProcessReceipt
    GamePassService.lua          # cached pass ownership checks
    LootService.lua              # server-authoritative weighted rolls
  client/                     # -> StarterPlayer.StarterPlayerScripts
    RevivePrompt.client.lua      # on-death dialog ("Revive (25 R$)")
    DungeonHUD.client.lua        # wave / boss bar / timer HUD
  shared/                     # -> ReplicatedStorage
    Remotes.lua                  # all RemoteEvents + explicit signatures
    DungeonConfig.lua            # tier definitions (waves, stats, caps)
    MonetizationConfig.lua       # PLACEHOLDER pass/product IDs  <-- EDIT ME
    LootTable.lua                # rarity weights + transparent drop-rate API
    ClassicPalette.lua           # allowed BrickColors whitelist
    StudsHelper.lua              # applyStuds / applyStudsToModel
    ClassicUI.lua                # makeFrame / makeButton / makeLabel
  assets/                     # -> ReplicatedStorage.Assets
    init.lua                     # asset manifest (textures/fonts/templates)
```

### Sync map (`default.project.json`)
| Source | Destination |
|---|---|
| `src/server` | `ServerScriptService` |
| `src/client` | `StarterPlayerScripts` |
| `src/shared` | `ReplicatedStorage` |
| `src/assets` | `ReplicatedStorage.Assets` |

Lighting properties (Legacy technology, Ambient 0,0,0, OutdoorAmbient 128,128,128, Brightness 1, no shadows/fog) are pinned in `default.project.json`.

## Using Rojo

```bash
rojo serve            # run from inside classic-dungeon-raid/ (where default.project.json lives)
```
1. Open Roblox Studio → Plugins → **Rojo**.
2. Click **Connect** while `rojo serve` runs.
3. Edits to `src/` hot-sync into Studio. Script types by suffix: `.server.lua` → Script, `.client.lua` → LocalScript, plain `.lua` → ModuleScript.
4. To build a one-shot place file instead: `rojo build -o game.rbxlx`.

## Plugging In Real Monetization IDs

Open **`src/shared/MonetizationConfig.lua`** and replace every placeholder:

1. Creator Hub → your game → **Monetization**:
   - **Game Passes**: create *2x XP & Loot*, *Extra Loadout Slot*, *VIP Dungeon Access*, *Auto-Revive* → paste numeric IDs into `GamePasses`.
   - **Developer Products**: create *Instant Revive (25 R$)*, *2x Damage Boost*, *Loot Box Key*, *Drop Rate Boost* → paste IDs into `DevProducts`.
2. No other file references raw IDs — everything reads from this config.

Also swap placeholder **texture/sky asset IDs** marked `TODO:` in:
- `src/shared/StudsHelper.lua` (`CLASSIC_STUD_TEXTURE_TOP/SIDE`)
- `src/server/ServerBootstrap.server.lua` (classic skybox faces)
- `src/assets/init.lua` (UI sfx/font manifest)

## Remote Signatures (contract — update both sides together)

| Event | Direction | Signature |
|---|---|---|
| PlayerDied | S→all C | `FireAllClients(runId: string, victimName: string)` |
| RequestRevive | C→S | `FireServer(runId: string)` |
| ReviveResult | S→C | `FireClient(player, success: boolean, remaining: number)` |
| WaveUpdate | S→all C | `FireAllClients(runId, waveNumber, totalWaves, enemiesAlive)` |
| BossHealthUpdate | S→all C | `FireAllClients(runId, bossName, health, maxHealth)` |
| RunComplete | S→all C | `FireAllClients(runId, outcome: "complete"\|"failed", lootSummary)` |

## Security Model
- **Never trust the client**: damage amounts are clamped server-side (`DungeonService.damageEnemy`), purchases are only honored via `ProcessReceipt` receipts (idempotent ledger keyed on `ReceiptId`; `PurchaseGranted` returned only after confirmed grant), revive requests are validated against active run membership + per-run cap + paid-token bucket.
- Loot rolls happen exclusively on the server; displayed drop rates derive from the same weight table used for rolling (`LootTable.getDisplayDropRates`).

## 2007 Visual Rules (enforced by convention)
1. **Every part studded on all 6 faces** — call `StudsHelper.applyStuds(part)` before parenting ANY runtime part; models use `applyStudsToModel`. Material is always Plastic.
2. **Colors** only from `ClassicPalette` (Bright red/blue/yellow/green, Br. yellowish green, Medium stone grey, Reddish brown, White, Black).
3. **Lighting** Legacy, no shadows/atmosphere/fog, classic sky.
4. **Characters** stay blocky R6; terrain avoided — dungeons are studded parts.
5. **UI** built only with `ClassicUI.makeFrame/makeButton/makeLabel`: grey fill + 2px black UIStroke, beveled buttons, SourceSans, **no UICorner**, no shadows/blur, single sanctioned gradient on the boss bar.

## Extending
- Add tiers: append to `DungeonConfig.Tiers` (+ matching `LootTable.Rewards` key).
- Replace placeholder cube enemies with real NPC models in `src/assets/PartTemplates/` — remember `applyStudsToModel` on spawn.
- Persist inventories by swapping `LootService.inventories` for DataStore calls.
