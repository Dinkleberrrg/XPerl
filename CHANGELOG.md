# Changelog (OctoWoW-Fork)

Unterschiede dieses Forks (Branch `octowow`) gegenüber Upstream
[Redbu11dev/X-Perl-UnitFrames](https://github.com/Redbu11dev/X-Perl-UnitFrames).
Geänderte Stellen im Code sind mit `[patch]` kommentiert.

**Basis:** Redbu11dev/X-Perl-UnitFrames `6d8a4a8` (2025-07-22)

> Der installierte Stand ist älter als der aktuelle Upstream. Zwei spätere Upstream-Commits fehlen lokal. Sie sind **keine** eigenen Änderungen und erscheinen im Diff gegen `main` nur als Rückschritt:
> - `933e015` „added ?? level display“ (Ziel-Level „??“ statt ausgeblendet, XPerl_Target.lua)
> - `11a4237` „Changed rested xp to show percentage“ (Rested-XP in Prozent statt absolut, XPerl_Player.lua)
>
> Nur die eigenen Änderungen zeigt: `git diff 6d8a4a8 octowow`

## HoT-Countdown auf Buff-Icons

- Neu: `XPerl/XPerl_HoTTimer.lua`. Eigene HoTs (Renew, Rejuvenation, Regrowth)
  zeigen auf den Buff-Icons der Party-, Raid-, Target- und Target-of-Target-Frames
  die Restdauer in Sekunden (gelb ab 6 s, rot ab 3 s).
- Benötigt SuperWoW: Gezählt wird über `UNIT_CASTEVENT` (wer hat welchen Zauber
  auf wen gewirkt), weil 1.12 keine Buff-Restdauer für fremde Einheiten kennt.
  Ohne SuperWoW bleibt das Modul inaktiv.
- Die Dauer lernt sich selbst: Landet ein eigener HoT auf dem Spieler, wird die
  echte Laufzeit per `GetPlayerBuffTimeLeft` gemessen und pro Charakter in
  `XPerl_HoTDurations` gespeichert. Talente, die die Dauer verlängern, sind so
  nach einem Selbst-Cast korrekt. Vorher gilt die Grunddauer 15/12/21 s.
- Grenze: Mehrere gleiche HoTs verschiedener Heiler auf einem Ziel lassen sich
  nicht unterscheiden; angezeigt wird die Zeit des eigenen.
- `XPerl/XPerl.xml`: lädt `XPerl_HoTTimer.lua`.
- `XPerl/XPerl.toc`: `## SavedVariablesPerCharacter: XPerl_HoTDurations`.

## Konfiguration und Profile (Stand aus der Installation)


### XPerl/XPerl_Globals.lua – Konfiguration pro Charakter repariert
- **Tiefe Kopie (`XPerl_DeepCopy`):** Konfigurationstabellen wurden überall per Referenz weitergegeben. Dadurch teilten sich Charaktere und der kontoweite Stand dieselben Farb-, Rand- und Raidtabellen; eine Änderung an einem Charakter schlug still auf alle anderen durch.
- **`XPerl_GlobalSlot()`:** legt `XPerlConfig_Global[realm]` bei Bedarf an. Vorher gab es „attempt to index field '?' (a nil value)“, wenn man „pro Charakter speichern“ ausschaltete, bevor ein Eintrag existierte. Auch `XPerl_ResetDefaults` stürzte auf einem frischen Account ab.
- **Neuer Charakter** erbt den kontoweiten Stand als Kopie statt als Referenz.
- **Rahmenpositionen werden gespeichert:** `XPerl_SavePosition`/`XPerl_RestorePosition` werden in der 1.12-Fassung nie aufgerufen, deshalb konnten Profile keine Positionen übertragen. Neu sind `XPerl_CapturePositions()` (bei Logout und Zonenwechsel) und `XPerl_ApplyPositions()` (rechnet unterschiedliche Skalierung um).

### XPerl_Options/XPerl_FrameOptions.lua – Optionen und Profil kopieren
- **Fallback für Slider:** OctoWoWs FrameXML stellt `OptionsFrame_DisableSlider`/`EnableSlider` nicht bereit, XPerl_Options stürzte bei jedem Laden ab. Jetzt mit eingebauter Originalimplementierung als Ersatz.
- **Charakterliste sortiert:** `pairs()` liefert in Lua 5.0 keine feste Reihenfolge. Die Liste wurde zweimal gebaut (Menü und Klick), daher konnte man einen Charakter anklicken und die Einstellungen eines anderen bekommen. Jetzt fest sortiert, `MyIndex` wird danach bestimmt und beim Öffnen vorbelegt.
- **„Einstellungen kopieren“ repariert:** tiefe Kopie statt Verlinkung der Untertabellen; die neue Tabelle wird auch im Per-Charakter-Speicher eingetragen (vorher war die Kopie nach dem nächsten Login weg); Positionen werden vorher gesichert (`XPerl_LastPositions`) und danach angewendet.
