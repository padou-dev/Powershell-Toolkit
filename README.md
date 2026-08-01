# Powershell-Toolkit

A small, self-updating collection of PowerShell functions I use daily in IT support and homelab work, with a one-command installer that stays out of your way: everything installs in **user scope** (no admin rights), your existing profile is **never overwritten**, and every file the installer touches is **backed up first**.

## Requirements

- PowerShell **7.0+** ([install](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)) — Windows PowerShell 5.1 is not supported
- Windows 10/11
- Optional: [Windows Terminal](https://aka.ms/terminal) and a [Nerd Font](https://www.nerdfonts.com/) for the full experience

## Installation

### Recommended: clone, read, run

```powershell
git clone https://github.com/padou-dev/Powershell-Toolkit.git
cd .\Powershell-Toolkit\
.\Setup.ps1
```

The installer detects it's running from a local clone and installs from your local files.

> [!NOTE]
> You're encouraged to read `Setup.ps1` before running it — it's short, commented, and you should never run scripts from the internet you haven't looked at. That's the whole reason cloning is the recommended path.

### Quick install

```powershell
irm https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1 | iex
```

> [!WARNING]
> This executes remote code directly. Convenient, but only use it if you trust this repo — prefer the clone method above.

## What gets installed

| Item | Location | Notes |
|---|---|---|
| Function scripts | `<ProfileDir>\Toolkit\Functions\` | Dot-sourced at shell startup |
| Menu | `<ProfileDir>\Toolkit\Menu.ps1` | Launched with the `toolkit` command |
| Profile block | Inside `$PROFILE`, between markers | Everything outside the markers is untouched; a timestamped backup is made on every change |
| Modules | CurrentUser scope | See `manifest.json` |
| Terminal schemes | Windows Terminal `settings.json` | 8 color schemes from `terminal_schemes.json`; original settings backed up first (skip with `-SkipTerminal`) |

`<ProfileDir>` is wherever your `$PROFILE` lives — the installer follows it, so OneDrive-redirected Documents folders work correctly.

## Usage

Open a new PowerShell window, then:

```powershell
toolkit          # interactive menu
Get-SysInfo      # or call any function directly
```

## Adding your own function

1. Drop `my_function.ps1` into `Functions/` (the file should define one `Verb-Noun` function)
2. Add an entry to `manifest.json`:

```json
{ "file": "my_function.ps1", "command": "Get-MyThing", "description": "What it does" }
```

3. Re-run `.\Setup.ps1`

The manifest is the single registry — the installer, the menu, and the update mechanism all read from it.

## Updating

Run `toolkit` and choose `U`, or re-run the installer.

## Uninstall

```powershell
.\Setup.ps1 -Uninstall
```

Removes the toolkit directory and the managed profile block. Backups are deliberately left behind.

## Troubleshooting

**`toolkit` isn't recognized after installing** — the profile only loads when a shell starts. Open a new window. If it still fails, check `$PROFILE` contains the `# >>> powershell-toolkit start >>>` block.

**Scripts are blocked from running** — your execution policy is restricting local scripts. Fix for your user only (no admin needed):
`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Functions load but Terminal looks wrong** — the color scheme is added but not activated. Windows Terminal → Settings → your profile → Appearance → select the `Toolkit` scheme.

**Something broke my profile** — restore any timestamped backup: `Copy-Item "$PROFILE.bak-<timestamp>" $PROFILE`

## VirusTotal integration (`hash_ls`)

`hash_ls` can look up file hashes on [VirusTotal](https://www.virustotal.com). To enable it, you need your own **free** VirusTotal API key (sign up, then Profile → API key) — on first run, `hash_ls` will offer to save it to the `VT_API_KEY` user environment variable. Without a key, hash lookups still work via the browser.

> [!IMPORTANT]
> **Disclaimer:**
> - This integration uses the VirusTotal **public API**, which is for **personal, non-commercial use only** — do not use it in commercial products or business workflows. See [VirusTotal's terms](https://docs.virustotal.com/reference/getting-started).
> - Only the **SHA256 hash** is sent to VirusTotal — never the file itself.
> - Results are a lookup, **not a verdict**. A hash unknown to VirusTotal (404) means *no data*, not *clean* — and 0 detections means no engine currently flags it, not that a file is guaranteed safe. This tool is not a substitute for antivirus software.
> - The free tier is rate-limited (4 lookups/minute, 500/day). Bring your own API key; never commit it to the repo.
> - This project is not affiliated with or endorsed by VirusTotal.

## License

[MIT](LICENSE)
