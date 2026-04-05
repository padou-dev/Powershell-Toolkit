# 🛠️ PowerShell Core IT Toolkit

A modular, "one-click" deployment system designed to standardize a PowerShell 7 environment across multiple machines. This toolkit automatically builds your local environment by syncing custom functions, visual enhancements, and an interactive menu directly from GitHub.

> [!IMPORTANT]
> **Requirements:** This script requires **PowerShell 7+** and **Administrator Privileges** for the initial setup.

---

## ⚡ Instant Installation (Pro Way)

If you have **PowerShell 7** installed, copy and paste this command into an **Administrator** terminal to deploy the entire toolkit automatically:

```
pwsh -ExecutionPolicy Bypass -Command "iex (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1')"
```

---

## 🚀 Manual Quick Start

> [!WARNING]
> **Do not "Right-Click > Run with PowerShell"**. This will attempt to run the script in Windows PowerShell 5.1, which is incompatible with this toolkit.

1. **Open PowerShell 7+** as an Administrator.
2. **Execute the setup:** Run `.\Setup.ps1` from your local repository.
3. **Automatic Sync:** The script will automatically create your `Functions` directory and download all toolkit modules from GitHub.
4. **Restart your Terminal** to load the new `$PROFILE`.
5. Type `menu` to launch the interactive toolkit.

---

## 🎨 Theme Gallery

The toolkit injects 8+ professional color schemes into your Windows Terminal. All screenshots feature the interactive `menu` with **Terminal-Icons** and a Nerd Font.

<table align="center">
  <tr>
    <td align="center"><b>Catppuccin Mocha</b><br><img src="images/catppuccin_mocha.png" width="400px"></td>
    <td align="center"><b>CyberPunk 2077</b><br><img src="images/cyberpunk_2077.png" width="400px"></td>
  </tr>
  <tr>
    <td align="center"><b>Dracula+</b><br><img src="images/dracula_plus.png" width="400px"></td>
    <td align="center"><b>GitHub Dark</b><br><img src="images/github_dark.png" width="400px"></td>
  </tr>
</table>

<details>
<summary><b>📸 Click to see more themes...</b></summary>
<br>

| Theme Name | Preview |
| :--- | :--- |
| **Apple System Colors** | ![Apple](images/apple_systems_colors.png) |
| **Flatland** | ![Flatland](images/flatland.png) |
| **Obsidian** | ![Obsidian](images/obsidian.png) |
| **Ubuntu** | ![Ubuntu](images/ubuntu.png) |

</details>
---

## 📦 Key Features

### 🔄 Dynamic Function Sync

The toolkit no longer relies on hardcoded scripts. It loops through a central registry on GitHub and downloads individual `.ps1` files into your local `Functions` folder. 

* **[U] Update:** Use the 'U' key in the menu to pull the latest logic, new functions, and theme updates instantly.

### 🛠️ Environment Standardization

* **Terminal-Icons:** Adds file-type icons to your directory listings.
* **PSReadLine:** Optimized with `MenuComplete` enabled on the **Tab** key.
* **Auto-Loader:** Dynamically "dot-sources" every script in your Functions folder on startup.

### 📋 Interactive Menu (`menu`)

A high-visibility dashboard for your daily IT tasks:

* **File Explorer:** View current folder contents with icons.
* **Function Picker:** Lists and executes all synced scripts by number.

---

## 🛠️ Included Functions

### `hash_ls`

A specialized audit tool for security and file integrity.

* **Features:** Displays SHA256 hashes, human-readable file sizes (MB/GB), and file icons for every file in the current directory.

### `mass_rename`

A safe, preview-first renaming tool. Displays a "Before and After" list and requires a `y/n` confirmation before applying changes.

### `space_to_dots`

Replaces all spaces in filenames within the current directory with periods (`.`) for terminal-friendly naming.

---

## 🎨 Visual Requirements

To see the icons correctly, you must use a **Nerd Font**.

1. Download a font (e.g., *JetBrains Mono Nerd Font*) from [nerdfonts.com](https://www.nerdfonts.com).
2. Install it on Windows.
3. Open Terminal Settings > **Appearance** > Set **Font face** to your Nerd Font.

---

## 📂 Local File Structure

* `Documents\PowerShell\Scripts\Menu.ps1` - The interactive manager.
* `Documents\PowerShell\Scripts\Functions\` - Your local library of synced scripts.

### ⚖️ License

Distributed under the MIT License. See LICENSE for more information.
