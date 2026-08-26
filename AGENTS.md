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

Die Roblox-Instanzen werden durch `default.project.json` gemappt:

- `src/shared` -> `ReplicatedStorage.Shared`
- `src/server` -> `ServerScriptService.Server`
- `src/client` -> `StarterPlayer.StarterPlayerScripts.Client`
- `Workspace.Baseplate` wird direkt in `default.project.json` definiert.

Konvention:

- Shared ModuleScripts kommen nach `src/shared`.
- Server-only Scripts und serverseitige Module kommen nach `src/server`.
- Client-only LocalScripts und clientseitige Module kommen nach `src/client`.
- Code, der sowohl Client als auch Server nutzen, gehoert nach `src/shared`.
- Server muss fuer Gameplay-Logik authoritative bleiben. Client darf Eingaben/UI liefern, aber keine Werte wie Ore-Menge, Geld, Schaden oder Mining-Erfolg vertrauenswuerdig bestimmen.

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

## Aktueller Startzustand

Das Projekt ist derzeit ein frisches Rojo-Grundgeruest mit Test-Prints:

- `src/server/init.server.luau`
- `src/server/Test.server.luau`
- `src/client/init.client.luau`
- `src/shared/Hello.luau`

Es gibt noch kein fertiges Mining-System. Sinnvolle naechste Systeme waeren:

- Ore-/Block-Definitionen in `src/shared`
- serverseitige Mining-Validierung
- RemoteEvents fuer Mining-Aktionen
- Inventar/Wallet auf dem Server
- einfache Client-UI fuer Tool, Ore-Anzeige und Feedback
