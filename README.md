# Taverners Ammo Guard

A lightweight ammunition monitor and merchant restock helper for WoW Forever. It uses **TavernersCore** for saved-variable defaults, shared theme colours, notifications, module registration and diagnostics.

## Requirements and installation

Requires WoW Forever and TavernersCore.

Install both folders:
- `Interface/AddOns/TavernersCore/`
- `Interface/AddOns/TavernersAmmoGuard/`

The TOC declares TavernersCore as a required dependency, so the client should load Core first.

## Supported characters and ammunition storage

Ammo Guard is active only for **Hunters, Rogues and Warriors**. Other classes are ignored: no ammo warnings, popups or automatic restocking.

Restocking is deliberately restricted to **equipped quivers and ammo pouches**:
- It checks equipped special-purpose bags in bag slots 1–4.
- The bag's family mask must match the currently equipped arrows or bullets.
- The general backpack and ordinary bags are never used as restock destinations.
- You must have a compatible quiver or ammo pouch equipped with free space.

## Defaults

- Ammunition support: arrows and bullets
- Warning threshold: 200 remaining
- Restock target: maximum capacity of free compatible quiver/ammo-pouch slots
- Automatic restock: enabled when opening a merchant who sells the currently equipped ammunition
- Low-ammo popup: enabled

## Commands

- `/ammo` or `/tammoguard` — open the Ammo Guard window
- `/ammo check` — check ammunition now
- `/ammo restock` — request a restock while the relevant merchant is open

## Behaviour

For an eligible class, Ammo Guard monitors the currently equipped projectile type. When the count reaches 200 or fewer, it displays a warning popup and a chat-screen notification. The warning is shown once per low-ammo episode. When an ammunition merchant opens, it looks for the exact equipped ammo item and requests purchases sized for the free space in compatible equipped quivers/ammo pouches only.

It will not buy a different projectile type or attempt purchases outside an open merchant window. If no compatible quiver/ammo pouch has free slots, the merchant does not sell the equipped ammo, or the expected merchant API is unavailable, it skips the purchase and records a diagnostic entry.

The client-reported bag-family and merchant APIs need live validation in WoW Forever. Please test the first merchant purchase with a small amount of free space in a quiver or ammo pouch before relying on unattended restocking.

## Core integration

The addon registers as the `AmmoGuard` module with `TavernersCore`, uses Core's database and notification services, and writes relevant events to the shared local diagnostics log. Open the Core diagnostics window with `/tcore`.

Settings are stored in `TavernersAmmoGuardDB`; the default configuration is both ammo types, maximum special-bag capacity, and a 200-ammo warning threshold.


## Shared settings (1.1.0)

Ammo Guard now registers its enabled state, warning threshold, automatic restocking and popup preferences with TavernersCore. These are available in `/tsettings`. Restocking remains subject to live merchant, equipped ammunition and compatible quiver/ammo-pouch checks; test purchases carefully in game.
