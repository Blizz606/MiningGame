# MiningGame Agent Guide

Dieses Repository ist ein Roblox Studio Projekt, das mit Rojo synchronisiert wird.
Arbeite so, dass Roblox Studio, Rojo und Git jederzeit nachvollziehbar bleiben.

## Projektkontext

- Projektname: `MiningGame`
- Rojo-Projektdatei: `default.project.json`
- Tooling wird ueber Aftman verwaltet: `aftman.toml`
- Rojo-Version: `rojo-rbx/rojo@7.7.0`
- Aktueller Remote: `origin` auf `https://github.com/Blizz606/MiningGame.git`

## Branch-Workflow

- `main` ist die stabile Branch und GitHub-Default-Branch.
- `develop` ist die normale Arbeitsbranch.
- Neue Features immer von `develop` abzweigen:

```bash
git checkout develop
git pull
git checkout -b feature/kurzer-name
```

- Bugfixes ebenfalls als eigene Branch von `develop` anlegen:

```bash
git checkout develop
git pull
git checkout -b fix/kurzer-name
```

- Groessere Experimente als `experiment/kurzer-name` anlegen.
- Keine direkte Arbeit auf `main`, ausser der Nutzer fordert es ausdruecklich.
- Vor Commits immer `git status --short --branch` pruefen.
- Keine fremden oder unerwarteten Aenderungen zuruecksetzen. Wenn der Working Tree dirty ist, erst verstehen, welche Dateien betroffen sind.
- Commits klein und beschreibend halten, z. B.:
  - `Add mining node definitions`
  - `Implement server mining validation`
  - `Create inventory UI shell`

## Rojo-Struktur

Die Roblox-Instanzen werden durch `default.project.json` gemappt.
Aktuell ist das Projectfile auf GUI-Script-Synchronisierung ausgelegt:

- `StarterGui` wird von Rojo angelegt/gefunden und nutzt `$ignoreUnknownInstances`.
- `StarterGui.MainGUI` und `StarterGui.ShopGUI` sind `ScreenGui`-Container mit `$ignoreUnknownInstances`.
- Die GUI-Frames, Buttons, Layouts, Images und sonstigen Studio-Objekte bleiben Studio-managed.
- Nur die explizit gemappten LocalScripts unter `StarterGui` und `ServerScriptService.Leaderbord` werden aus VS Code/Rojo synchronisiert.
- `MainGUI`, `HUD`, `LeftHUD`, `Buttons`, `ShopButton`, `ShopGUI`, `ShopLayer` und `ShopHolder` nutzen `$ignoreUnknownInstances`, damit Rojo unbekannte GUI-Kinder nicht loescht.

Aktuelle GUI-Script-Zuordnung:

- `StarterGui.GuiPreloader` -> `src/client/GuiPreloader.client.luau`
- `StarterGui.MainGUI.ButtonEffects` -> `src/client/MainGUI/ButtonEffects.client.luau`
- `StarterGui.MainGUI.MainController` -> `src/client/MainGUI/MainController.client.luau`
- `StarterGui.MainGUI.HUD.LeftHUD.Buttons.ShopButton.ShopButtonController` -> `src/client/MainGUI/ShopButton.client.luau`
- `StarterGui.ShopGUI.ShopLayer.CloseController` -> `src/client/ShopGUI/CloseController.client.luau`
- `StarterGui.ShopGUI.ShopLayer.ShopHolder.BuyButtonHoverController` -> `src/client/ShopGUI/BuyButtonHoverController.client.luau`
- `StarterGui.ShopGUI.ShopLayer.ShopHolder.ShopController` -> `src/client/ShopGUI/ShopController.client.luau`
- `StarterGui.ShopGUI.ShopLayer.ShopHolder.PageController` -> `src/client/ShopGUI/PageController.client.luau`

Wichtig:

- `MainController` und `ShopButtonController` duerfen nie auf dieselbe Datei zeigen.
- Fuer dieses Setup immer explizit `rojo serve default.project.json` verwenden.
- `backup/syncback/syncback.project.json` ist nur ein Backup/Syncback-Artefakt. Nicht versehentlich damit serven, weil es `StarterGui` direkt auf `.rbxm`-Modelle mappt.
- `src/server/Leaderbord.server.luau` ist als `ServerScriptService.Leaderbord` gemappt.
- Weitere Gameplay-Dateien unter `src/server/Systems`, `src/shared`, `src/starterpack` und `src/workspace` existieren, sind im aktuellen `default.project.json` aber nicht gemappt.

Konvention:

- Shared ModuleScripts kommen nach `src/shared`.
- Server-only Scripts und serverseitige Module kommen nach `src/server`.
- Client-only LocalScripts und clientseitige Module kommen nach `src/client`.
- Code, der sowohl Client als auch Server nutzen, gehoert nach `src/shared`.
- Server muss fuer Gameplay-Logik authoritative bleiben. Client darf Eingaben/UI liefern, aber keine Werte wie Ore-Menge, Geld, Schaden oder Mining-Erfolg vertrauenswuerdig bestimmen.

## Script-Inventar

GUI-Scripts, die aktuell ueber `default.project.json` synchronisiert werden:

- `src/client/GuiPreloader.client.luau`
  - LocalScript unter `StarterGui.GuiPreloader`.
  - Laeuft beim Clientstart im Hintergrund und blockiert keine HUD-/Shop-Controller.
  - Sammelt moeglichst alle preloadbaren GUI-Assets aus allen direkten `PlayerGui`-Kindern und deren Descendants.
  - Erfasst ganze Instanzen plus Content-Properties wie `Image`, `HoverImage`, `PressedImage`, `Video`, `SoundId`, `AnimationId`, `Texture`, `TextureId`, `MeshId` und `Graphic`.
  - Laedt zusaetzlich die festen selected Tab-Icon-Asset-IDs vor.
  - Laedt `ShopGUI` priorisiert und setzt danach `PlayerGui.ShopGuiAssetsPreloaded = true`.
  - Preloadet in kleinen Batches und loggt Start, Item-Anzahl, gedrosselten Ladefortschritt und Abschluss.
  - Beobachtet spaeter hinzukommende GUI-Descendants und laedt deren Assets nach.
  - Setzt nach dem Versuch `PlayerGui.GuiAssetsPreloaded = true` als Attribute.

- `src/client/MainGUI/ButtonEffects.client.luau`
  - LocalScript unter `MainGUI.ButtonEffects`.
  - Sucht `HUD.LeftHUD.Buttons` und `HUD.LeftHUD.Currencies`.
  - Fuegt `GuiButton`-Kindern bei Bedarf einen `UIScale` namens `HoverScale` hinzu.
  - Animiert Hover, MouseLeave, MouseButton1Down und MouseButton1Up per `TweenService`.
  - Beobachtet spaeter hinzugefuegte Buttons per `DescendantAdded`.

- `src/client/MainGUI/MainController.client.luau`
  - LocalScript unter `MainGUI.MainController`.
  - Erwartet `leaderstats.Money` und `PlayerData.Diamonds`.
  - Erwartet `HUD.LeftHUD`, `Currencies`, `Currencies.Money.PlusButton`, `Buttons` und `Buttons.UIGridLayout`.
  - Oeffnet beim Klick auf `Money.PlusButton` den Shop und fordert ueber `ShopHolder.OpenPageRequest` die Cash-Seite an.
  - Wartet beim Oeffnen kurz auf `PlayerGui.ShopGuiAssetsPreloaded`, damit der Shop nicht halb geladen sichtbar wird.
  - Verwendet `ReplicatedStorage.Text` fuer CFM/Custom-Text und legt ein Text-GUI in `PlayerGui` an.
  - Formatiert Money/Diamonds als K/M/B/T und haelt die Texte auf den Amount-Frames positioniert.
  - Spielt beim Erhoehen von Money oder Diamonds eine kurze Pulse-Animation auf dem jeweiligen Currency-Frame.
  - Passt HUD-Scale, Button-Grid und Textgroessen fuer Handy, Tablet und Desktop an.
  - Aktualisiert Positionen auf `RenderStepped` und bei `ViewportSize`-Aenderungen.

- `src/client/MainGUI/ShopButton.client.luau`
  - LocalScript unter `MainGUI.HUD.LeftHUD.Buttons.ShopButton.ShopButtonController`.
  - Erwartet `PlayerGui.ShopGUI.ShopLayer.ShopHolder` und `ShopLayer.DimButton`.
  - Erstellt bei Bedarf `ShopHolder.UIScale`.
  - Oeffnet den Shop mit Scale-Tween und DimButton-Fade.
  - Wartet beim Oeffnen kurz auf `PlayerGui.ShopGuiAssetsPreloaded`, damit Shop-Assets vorher geladen sind.
  - Schuetzt gegen doppeltes Oeffnen mit `isOpening`.
  - Enthalt viele Debug-Prints fuer Open-Flow und fehlende GUI-Objekte.

- `src/client/ShopGUI/CloseController.client.luau`
  - LocalScript unter `ShopGUI.ShopLayer.CloseController`.
  - Erwartet `ShopLayer.ShopHolder`, `ShopLayer.DimButton` und `ShopHolder.UIScale`.
  - Lauscht global auf MouseButton1/Touch via `UserInputService.InputBegan`.
  - Prueft per absoluter ShopHolder-Hitbox, ob der Klick ausserhalb des Shops liegt.
  - Schliesst den Shop mit Scale-Tween und Dim-Fade und setzt danach Scale/Transparenz zurueck.
  - Enthalt ausfuehrliches Debug-Logging inklusive `GetGuiObjectsAtPosition`.

- `src/client/ShopGUI/BuyButtonHoverController.client.luau`
  - LocalScript unter `ShopGUI.ShopLayer.ShopHolder.BuyButtonHoverController`.
  - Sucht alle descendants mit `Name == "BuyButton"` und `ClassName == ImageButton`.
  - Deaktiviert `AutoButtonColor`.
  - Erstellt bei Bedarf `HoverScale` und animiert Hover/Pressed/Release.
  - Erkennt spaeter eingefuegte BuyButtons per `DescendantAdded`.

- `src/client/ShopGUI/ShopController.client.luau`
  - LocalScript unter `ShopGUI.ShopLayer.ShopHolder.ShopController`.
  - Erwartet `ShopHolder.Tabs` mit `PassesButton`, `CashButton`, `GemsButton`, `BoostsButton`.
  - Erwartet `ShopHolder.Pages.CashPage` mit Cash-Angeboten `Cash_5000`, `Cash_15000`, `Cash_40000`, `Cash_100000`, `Cash_275000`, `Cash_650000`.
  - Erstellt/findet `ShopHolder.OpenPageRequest` und waehlt darueber angeforderte Tabs auch von anderen Scripts aus.
  - Speichert die normalen Button-Images aus Studio und ersetzt sie beim Selektieren durch feste selected Asset-IDs.
  - Erstellt je Tab-Button einen `UIScale` namens `ButtonScale`.
  - Animiert den Icon-Wechsel mit kurzem Shrink/Fade/Pop.
  - Verbindet die sechs Cash-`BuyButton`s clientseitig mit `MarketplaceService:PromptProductPurchase`.
  - Verbindet die sechs Gems-`BuyButton`s unter `Pages.GemPage`/`Pages.GemsPage` clientseitig mit `MarketplaceService:PromptProductPurchase`.
  - Nutzt lokale Cash- und Gems-Product-Tabellen, damit die Tab-Auswahl nicht von `ReplicatedStorage`-Configs blockiert wird.
  - Deaktiviert Shop-`BuyButton`s waehrend ein Kauf-Prompt offen ist und aktiviert sie nach `PromptProductPurchaseFinished` wieder.
  - Developer Product IDs:
    - `Cash_5000` -> `3710684905`
    - `Cash_15000` -> `3710684949`
    - `Cash_40000` -> `3710684981`
    - `Cash_100000` -> `3710685014`
    - `Cash_275000` -> `3710685083`
    - `Cash_650000` -> `3710685142`
    - `Gems_100` -> `3710761179`
    - `Gems_250` -> `3710761239`
    - `Gems_600` -> `3710761278`
    - `Gems_1500` -> `3710761312`
    - `Gems_3500` -> `3710761340`
    - `Gems_8000` -> `3710761364`
  - Die echte Cash-/Gems-Auszahlung passiert serverseitig in `ServerScriptService.Leaderbord`.
  - Setzt beim Start `Passes` als aktiven Tab.

- `src/client/ShopGUI/PageController.client.luau`
  - LocalScript unter `ShopGUI.ShopLayer.ShopHolder.PageController`.
  - Erwartet `ShopHolder.Tabs` und `ShopHolder.Pages`.
  - Erstellt/findet `ShopHolder.OpenPageRequest` und oeffnet darueber angeforderte Pages auch von anderen Scripts.
  - Erwartet `PassesPage` und `CashPage`; `GemPage`/`GemsPage` und `BoostsPage`/`BoostPage` sind optional.
  - Schaltet Pages passend zu den Tab-Buttons um.
  - Bereitet Angebotskarten-Frames mit `PageAnimScale` vor und animiert sie gestaffelt.
  - Nutzt `animationVersion`, damit alte verzogerte Animationen nach einem schnellen Tabwechsel abbrechen.
  - Enthalt noch einen Rojo-Test-Print beim Start.

Server-Script und weitere vorhandene Scripts:

- `src/server/init.server.luau`
  - Startet `MineGenerator.Start()` und `MiningService.Start()`.

- `src/server/Leaderbord.server.luau`
  - Script unter `ServerScriptService.Leaderbord`.
  - Erstellt beim Join `leaderstats` mit `Money`, `Blocks`, `Rebirths`, alle mit Startwert `0`.
  - Erstellt `PlayerData.Diamonds` mit Startwert `0`.
  - Verarbeitet Cash- und Gems-Developer-Products ueber `MarketplaceService.ProcessReceipt`.
  - Nutzt eine lokale Product-ID-zu-Reward-Tabelle fuer Developer-Products.
  - Erhoeht `leaderstats.Money` serverseitig fuer die Product IDs:
    - `3710684905` -> `5_000`
    - `3710684949` -> `15_000`
    - `3710684981` -> `40_000`
    - `3710685014` -> `100_000`
    - `3710685083` -> `275_000`
    - `3710685142` -> `650_000`
  - Erhoeht `PlayerData.Diamonds` serverseitig fuer die Product IDs:
    - `3710761179` -> `100`
    - `3710761239` -> `250`
    - `3710761278` -> `600`
    - `3710761312` -> `1_500`
    - `3710761340` -> `3_500`
    - `3710761364` -> `8_000`
  - Laedt und speichert persistente Spielerwerte ueber `DataStoreService` mit `PlayerData_v1`.
  - Speichert beim Leave, beim Server-Shutdown, nach Wertaenderungen mit kurzem Debounce und periodisch alle 60 Sekunden.
  - Speichert verarbeitete Receipts im Spielerprofil, damit bereits verarbeitete Purchases nicht nochmal ausgezahlt werden.
  - Serialisiert DataStore-Schreibzugriffe pro Spieler mit einer lokalen Schreibsperre, damit Autosave und Receipt-Verarbeitung nicht gegeneinander schreiben.
  - Begrenzt gespeicherte `IntValue`-Werte auf den sicheren Bereich `0` bis `2_147_483_647`.
  - Receipt-Verarbeitung schreibt Kauf-Grant und Receipt-Markierung gemeinsam per `UpdateAsync` in dasselbe Spielerprofil.
  - Wenn ein Daten-Load fehlschlaegt, wird normales Speichern fuer diese Session deaktiviert, damit alte echte Daten nicht mit Startwerten ueberschrieben werden.
  - Gibt bei temporaeren Fehlern `NotProcessedYet` zurueck, damit Roblox die Receipt-Verarbeitung spaeter erneut versuchen kann.

- `src/server/Test.server.luau`
  - Leeres Test-Script ohne Runtime-Logs.

- `src/server/Systems/MineGenerator.luau`
  - Serverseitiges Modul fuer prozedurale Mine-Bloecke.
  - Erwartet `Workspace.MineBounds.TopCorner` und `Workspace.MineBounds.BottomCorner` als Studio-gesetzte `BasePart`-Marker.
  - Berechnet daraus Grid, Tiefe und Blockpositionen.
  - Bricht mit Warnung statt hartem Server-Abbruch ab, wenn Bounds fehlen oder zu gross sind.
  - Limitiert Layer auf maximal `25_000` Bloecke pro Layer.
  - Verschiebt/klont die Bounds-Marker nach `ServerStorage.MineBoundsSnapshot` und entfernt sie aus `Workspace`.
  - Erzeugt `Workspace.Mine.Layers.Depth_n` und darin verankerte 4x4x4-Bloecke.
  - Erzeugt Bloecke in Batches, damit grosse Layer nicht in einem Frame gespawnt werden.
  - Waehlt Ore-Varianten gewichtet aus und setzt Attribute wie `MineBlock`, `OreType`, `GridX`, `GridZ`, `Depth`.
  - Berechnet Ore-Gewichte einmalig vor statt pro Block.
  - Setzt `CanTouch = false` und `CastShadow = false` auf Mine-Bloecken fuer bessere Performance.
  - Generiert anfangs zwei sichtbare Layer und beim Zerstoeren tiefer Bloecke weitere Layer nach.
  - Startet Nachgenerierung aus Destroy-Callbacks per `task.spawn`, damit Destroy/Mining nicht blockiert.
  - Nutzt eine Generation-ID, damit alte Destroy-Callbacks nach Mine-Reset keine neuen Layer erzeugen.
  - Loggt im normalen Ablauf nicht.

- `src/server/Systems/MiningService.luau`
  - Serverseitiges Modul fuer Mining-Validierung.
  - Erwartet `ReplicatedStorage.Remotes.MineBlockRequest` als `RemoteEvent`.
  - Nimmt Client-Ziele entgegen, validiert Cooldown, `MineBlock`-Attribut, Workspace-Zugehoerigkeit und Distanz zum `HumanoidRootPart`.
  - Zerstoert gueltige Mine-Bloecke server-authoritative.

- `src/starterpack/Pickaxe/MineClient.client.luau`
  - LocalScript fuer ein Pickaxe-Tool.
  - Erwartet als Parent ein `Tool`.
  - Speichert beim Equip das Roblox-Mouse-Objekt.
  - Sendet bei Aktivierung nur dann `MineBlockRequest`, wenn `mouse.Target` ein MineBlock ist.

- `src/workspace/KillZone/KillOnTouch.server.luau`
  - ServerScript fuer eine KillZone-`BasePart`.
  - Prueft auf jedem Heartbeat alle Player-Characters.
  - Toetet nur, wenn die gesamte Character-BoundingBox innerhalb der KillZone liegt.
  - Nutzt eine kurze `killedHumanoids`-Sperre gegen mehrfaches Setzen.

- `src/client/init.client.luau`
  - Leeres Client-Test-Script ohne Runtime-Logs.

- `src/shared/Hello.luau`
  - Einfaches Test-Modul, das eine Funktion mit `Hello, world!`-Print zurueckgibt.

## Rojo/Aftman Befehle

Wenn `rojo` im PATH verfuegbar ist:

```bash
rojo serve
rojo build -o "MiningGame.rbxlx"
```

Falls `rojo` nicht gefunden wird, liegt der Aftman-Bin-Ordner normalerweise hier:

```text
C:\Users\jaron\.aftman\bin
```

Dieser Ordner sollte im User-PATH stehen. Danach ein neues Terminal starten.

Nutzbare Pruefungen:

```bash
rojo --version
aftman --version
git status --short --branch
```

## Roblox/Luau Regeln

- Luau-Dateien mit `.luau` verwenden.
- Keine Secrets, Tokens oder privaten API-Keys ins Repository committen.
- RemoteEvents/RemoteFunctions nur mit serverseitiger Validierung verwenden.
- Clientdaten nie direkt vertrauen.
- Shared Configs bevorzugt als reine Tabellen/ModuleScripts bauen.
- Module klein und klar halten: Definitionen, Services, Controller und UI-Logik getrennt strukturieren.
- Bei spaeterem Ausbau bevorzugte Struktur:

```text
src/
  shared/
    Config/
    Remotes/
    Types/
  server/
    Services/
    Systems/
  client/
    Controllers/
    UI/
```

## Dateien, die nicht committed werden sollen

Siehe `.gitignore`:

- `MiningGame.rbxlx`
- Roblox Studio Lockfiles: `*.rbxlx.lock`, `*.rbxl.lock`
- `sourcemap.json`

Die `.gitattributes` sorgt fuer konsistente LF-Line-Endings fuer Projektdateien.

## Erwarteter Arbeitsablauf fuer Agenten

1. Projektzustand pruefen:

```bash
git status --short --branch
git branch -vv
```

2. Auf passender Branch arbeiten. Standard ist `develop`.
3. Relevante Dateien lesen, bevor Code geaendert wird.
4. Kleine, nachvollziehbare Aenderungen machen.
5. Wenn moeglich lokal pruefen:

```bash
rojo build -o "MiningGame.rbxlx"
```

6. Ergebnis zusammenfassen und erwaehnen, welche Pruefungen gelaufen sind.

## Aktueller Projektzustand

Das Projekt enthaelt derzeit zwei Arbeitsbereiche:

- Ein aktuelles Rojo-Setup fuer Studio-managed GUI mit VS-Code-managed LocalScripts in `StarterGui`.
- Aeltere bzw. derzeit nicht gemappte Gameplay-Scripts fuer Mine-Generierung, Mining-Remote, Pickaxe-Client und KillZone.

Vor weiterer Arbeit immer beachten:

- `default.project.json` synchronisiert aktuell nur die GUI-Scripts unter `StarterGui`.
- Wenn Gameplay-Scripts wieder ueber Rojo synchronisiert werden sollen, muss `default.project.json` bewusst erweitert werden.
- Die Studio-GUI bleibt die Quelle fuer Frames, Buttons, Images, Layouts, UIScales und sonstige visuelle Objekte.
- Vor dem Verbinden mit Studio kann `rojo sourcemap default.project.json` genutzt werden, um die LocalScript-Zuordnung gefahrlos zu pruefen.
