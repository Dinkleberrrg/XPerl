# Changelog (OctoWoW build) – XPerl

Differences of this addon from upstream
[Redbu11dev/X-Perl-UnitFrames](https://github.com/Redbu11dev/X-Perl-UnitFrames) (folder `XPerl`).
Changed places in the code are marked with `[patch]`.
This repository was split from [Dinkleberrrg/X-Perl-UnitFrames](https://github.com/Dinkleberrrg/X-Perl-UnitFrames) (branch `octowow`) so the Octo launcher can install it via git URL; the history was preserved.

**Base:** Redbu11dev/X-Perl-UnitFrames `6d8a4a8` (2025-07-22)

> The installed version is older than the current upstream. Two later upstream commits are missing locally. They are **not** own changes and only show up as a regression in a diff against upstream:
> - `933e015` "added ?? level display" (target level "??" instead of hidden, XPerl_Target.lua)
> - `11a4237` "Changed rested xp to show percentage" (rested XP as a percentage instead of absolute, XPerl_Player.lua)

## HoT countdown on buff icons

- New: `XPerl/XPerl_HoTTimer.lua`. Your own HoTs (Renew, Rejuvenation, Regrowth) show their remaining time in seconds on the buff icons of the party, raid, target and target-of-target frames (yellow below 6 s, red below 3 s).
- Requires SuperWoW: casts are tracked via `UNIT_CASTEVENT` (who cast which spell on whom), because 1.12 has no buff duration API for other units. Without SuperWoW the module stays inactive.
- The duration learns itself: when one of your HoTs lands on yourself, the real duration is measured with `GetPlayerBuffTimeLeft` and stored per character in `XPerl_HoTDurations`. Talents that extend the duration are thus correct after one self-cast. Until then the base durations 15/12/21 s apply.
- Limitation: identical HoTs from different healers on one target cannot be told apart; your own timer is shown.
- `XPerl/XPerl.xml`: loads `XPerl_HoTTimer.lua`.
- `XPerl/XPerl.toc`: `## SavedVariablesPerCharacter: XPerl_HoTDurations`.

## Configuration and profiles

### XPerl_Globals.lua – per-character configuration fixed
- **Deep copy (`XPerl_DeepCopy`):** Configuration tables were passed around by reference everywhere. Characters and the account-wide settings therefore shared the same colour, border and raid tables; a change on one character silently affected all others.
- **`XPerl_GlobalSlot()`:** creates `XPerlConfig_Global[realm]` when needed. Before, turning off "save per character" before an entry existed raised "attempt to index field '?' (a nil value)". `XPerl_ResetDefaults` also crashed on a fresh account.
- **New characters** inherit the account-wide settings as a copy instead of a reference.
- **Frame positions are saved:** `XPerl_SavePosition`/`XPerl_RestorePosition` are never called in the 1.12 version, so profiles could not transfer positions. New: `XPerl_CapturePositions()` (on logout and zoning) and `XPerl_ApplyPositions()` (converts between different scales).

### XPerl_Options/XPerl_FrameOptions.lua (repository XPerl_Options) – options and copying profiles
- **Slider fallback:** OctoWoW's FrameXML does not provide `OptionsFrame_DisableSlider`/`EnableSlider`, so XPerl_Options crashed on every load. It now falls back to a built-in copy of the original implementation.
- **Character list sorted:** `pairs()` has no fixed order in Lua 5.0. The list was built twice (menu and click), so clicking one character could load another character's settings. It is now sorted, `MyIndex` is determined afterwards and preselected when opening.
- **"Copy settings" fixed:** deep copy instead of linking sub-tables; the new table is also stored in the per-character slot (before, the copy was gone after the next login); positions are saved first (`XPerl_LastPositions`) and applied afterwards.
