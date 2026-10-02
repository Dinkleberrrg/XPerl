# XPerl

X-Perl UnitFrames core module: player, target, party and pet frames. Contains the OctoWoW fixes, see CHANGELOG.md.

## Notable changes

Fork of **Redbu11dev/X-Perl-UnitFrames**.

- Per-character settings no longer leak into other characters (deep copies instead of shared tables).
- Fixed Lua errors when toggling "save per character" or resetting on a fresh account.
- Frame positions are saved and transferred when copying a profile.
- New: HoT countdown on buff icons for your own Renew/Rejuvenation/Regrowth (needs SuperWoW).

Details: [CHANGELOG.md](CHANGELOG.md)

Part of X-Perl UnitFrames (Redbu11), split into one repository per addon folder so the Octo launcher can install and update it via git URL.

- Original: https://github.com/Redbu11dev/X-Perl-UnitFrames
- Full fork with all modules: https://github.com/Dinkleberrrg/X-Perl-UnitFrames (branch `octowow`)
- Installation: add `https://github.com/Dinkleberrrg/XPerl` as a custom git addon in the Octo launcher, or copy the folder `XPerl` to `Interface\AddOns`.
