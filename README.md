# Taverners Ammo Guard

A lightweight ammunition monitor and merchant restock helper for WoW Forever. It uses **TavernersCore** for saved-variable defaults, shared theme colours, notifications, module registration and diagnostics.

## Requirements and installation

Requires WoW Forever and TavernersCore.

Install both folders:
- `Interface/AddOns/TavernersCore/`
- `Interface/AddOns/TavernersAmmoGuard/`

The TOC declares TavernersCore as a required dependency, so the client should load Core first.

## Defaults

- Ammunition support: arrows and bullets
- Warning threshold: 200 remaining
- Restock target: maximum capacity based on free compatible bag slots
- Automatic restock: enabled when opening a merchant who sells the currently equipped ammunition
- Low-ammo popup: enabled

## Commands

- `/ammo` or `/tammoguard` — open the Ammo Guard window
- `/ammo check` — check ammunition now
- `/ammo restock` — request a restock while the relevant merchant is open

## Behaviour

Ammo Guard monitors the currently equipped projectile type. When the count reaches 200 or fewer, it displays a warning popup and a chat-screen notification. The warning is shown once per low-ammo episode. When an ammunition merchant opens, it looks for the exact equipped ammo item and requests enough purchases to use the free compatible bag slots reported by the client.

It will not buy a different projectile type or attempt purchases outside an open merchant window. If there are no compatible free slots, the merchant does not sell the equipped ammo, or the expected merchant API is unavailable, it skips the purchase and records a diagnostic entry.

The initial restock calculation is intentionally conservative but depends on the WoW Forever client's merchant and bag-family APIs. Please test the first merchant purchase with a small amount of free space before relying on unattended restocking.

## Core integration

The addon registers as the `AmmoGuard` module with `TavernersCore`, uses Core's database and notification services, and writes relevant events to the shared local diagnostics log. Open the Core diagnostics window with `/tcore`.

Settings are stored in `TavernersAmmoGuardDB`; the default configuration is both ammo types, maximum restock target, and a 200-ammo warning threshold.
