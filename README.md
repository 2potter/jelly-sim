# 🍮 Jelly Simulator

A Roblox game where you pop wobbly jelly blobs, hatch eggs, and collect jelly pets
that swarm the blobs for you. Unlock new zones, buy upgrades, and hunt for a
Mythical pet!

## How to play

- **Click (or tap) a jelly blob** and your pets run over and attack it. Click it again to call them back.
- When a blob pops, you get **Jelly** 🍮 (that's the money).
- Walk up to an **egg** and hold **E** to hatch a new pet.
- Walk up to a glowing **gate button** to unlock the next zone.
- Press **🐾 Pets** to equip pets (click a pet) or delete them (red X).
- Press **⬆️ Upgrades** to make your pets stronger, get more Jelly, carry more pets, and run faster.
- Turn **Auto: ON** and your pets find blobs by themselves.

---

## Setting it up on Windows (step by step)

You only need to do steps 1 to 4 once.

### 1. Install Git

1. Go to **https://git-scm.com/download/win** and download the installer.
2. Open it and keep clicking **Next** (the normal options are fine), then **Install**.

### 2. Install Rokit (it installs Rojo for you)

Rojo is the tool that sends the code from this folder into Roblox Studio.

1. Go to **https://github.com/rojo-rbx/rokit/releases** and download the file that ends in
   **`windows-x86_64.zip`** from the newest release.
2. Right-click the zip and pick **Extract All**.
3. Open the extracted folder, click the address bar at the top, type `powershell`, and press **Enter**.
4. In the blue window, type this and press **Enter**:
   ```
   .\rokit.exe self-install
   ```
5. Close that window.

### 3. Download the game code

1. Press the **Windows key**, type `powershell`, and open **Windows PowerShell**.
2. Type these one at a time, pressing **Enter** after each:
   ```
   cd ~\Documents
   git clone https://github.com/2potter/jelly-sim.git
   cd jelly-sim
   rokit install
   ```
   If it asks whether you trust `rojo-rbx/rojo`, type `y` and press **Enter**.

### 4. Install the Rojo plugin in Roblox Studio

Close Roblox Studio first, then in the same PowerShell window type:

```
rojo plugin install
```

### 5. Play the game!

1. In PowerShell (inside the `jelly-sim` folder), type:
   ```
   rojo serve
   ```
   Leave this window open. It says something like `Rojo server listening on port 34872`.
2. Open **Roblox Studio** and make a new **Baseplate**.
3. Click the **Plugins** tab, then **Rojo**, then **Connect**.
4. Press **Play** ▶️. You start in Gummy Meadow with a free pet!

Next time you only need step 5. If you open a new PowerShell window, type
`cd ~\Documents\jelly-sim` first.

To get new code from GitHub later, type `git pull` in the `jelly-sim` folder.

### Turning on saving

Saving uses Roblox DataStores, which only work in Studio after two things:

1. **File → Publish to Roblox** (publish your place once).
2. **Home → Game Settings → Security → Enable Studio Access to API Services → ON**, then **Save**.

Without this the game still works, your Jelly just resets every time you press Play.

---

## Where things are

| Folder | What's inside | Where it goes in Studio |
| --- | --- | --- |
| `src/shared` | `Config` (all the numbers, pets, zones, eggs), pet models, number formatting | ReplicatedStorage → Shared |
| `src/server` | the world builder, jelly blobs, pets, saving, and `Main` that starts it all | ServerScriptService → Server |
| `src/client` | the screen stuff: Jelly counter, menus, hatch animation, gates | StarterPlayerScripts → Client |

**Want to change something? Start with `src/shared/Config.luau`.** You can add pets, make eggs
cheaper, add a fourth zone, or make blobs give more Jelly, all in that one file.
Save the file while `rojo serve` is running and Studio updates by itself.
