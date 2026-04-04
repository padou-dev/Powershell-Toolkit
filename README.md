# 🛠️ PowerShell Core IT Toolkit

A portable, "one-click" deployment script designed to standardize a PowerShell 7 environment across multiple machines. This toolkit automates folder structures, installs visual enhancements, and provides a custom interactive menu for common IT tasks.

> [!IMPORTANT]
> **Requirements:** This script requires **PowerShell 7+** and **Administrator Privileges** for the initial setup.

---

## ⚡ Instant Installation (Pro Way)

If you have **PowerShell 7** installed and want to skip the manual download, copy and paste this command into an **Administrator** terminal:

```powershell
pwsh -ExecutionPolicy Bypass -Command "iex (New-Object System.Net.WebClient).DownloadString('[https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1](https://raw.githubusercontent.com/padou-dev/Powershell-Toolkit/main/Setup.ps1)')"
```

---

## 🚀 Manual Quick Start

> [!WARNING]
> **Do not "Right-Click > Run with PowerShell"**. This will attempt to run the script in Windows PowerShell 5.1, which is incompatible with this toolkit.

### Correct Installation Steps:

1. **Open PowerShell 7+** as an Administrator.
2. **Navigate** to the folder containing your downloaded files:
   ```powershell
   cd C:\Path\To\Your\Downloads\Powershell-Toolkit
   ```
3. **Execute** the script by typing:
   ```powershell
   .\Setup.ps1
   ```
4. **Follow the Interactive Prompts:** Choose your themes and opacity settings.
5. **Restart your Terminal** to load the new `$PROFILE` and UI enhancements.

---

## 🎨 Customization Options

During installation, you will have the choice to opt-in to the following:

### 🌈 Professional Color Schemes
Injects 8 high-quality themes into your Windows Terminal settings without overwriting your existing profiles:
* **Catppuccin Mocha** (Modern Dark)
* **CyberPunk 2077** (High Contrast)
* **Dracula+** & **Obsidian** (Classic Developer Favorites)
* **Apple & Ubuntu** (System-inspired palettes)
* **GitHub Dark** & **Hacktober**

### 🪟 UI Transparency
* **92% Opacity:** Applies a subtle, professional transparency to all terminal profiles for a modern "Glass" aesthetic.

---

## 🎨 Theme Gallery

Take a look at the curated color schemes included in this toolkit. All screenshots feature the interactive `menu` command with **Terminal-Icons** enabled and a Nerd Font installed.

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
<summary><b>📸 Click to see all 10 themes...</b></summary>
<br>

| Theme Name | Preview |
| :--- | :--- |
| **Apple System Colors** | ![Apple](images/apple_systems_colors.png) |
| **Flatland** | ![Flatland](images/flatland.png) |
| **Hacktober** | ![Hacktober](images/hacktober.png) |
| **Obsidian** | ![Obsidian](images/obsidian.png) |
| **Ottosson** | ![Ottosson](images/ottosson.png) |
| **Ubuntu** | ![Ubuntu](images/ubuntu.png) |

</details>

---

## 📦 Key Features

### 🔄 Self-Updating Core
* **[U] Update:** The interactive menu includes a built-in update function that pulls the latest version of the toolkit directly from GitHub, ensuring your functions and themes are always current.

### 🛠️ Environment Standardization
The script automatically configures your `$PROFILE` with the following:
* **Terminal-Icons:** Adds file-type icons to your directory listings.
* **PSReadLine:** Optimized with `MenuComplete` enabled on the **Tab** key.
* **Auto-Loader:** Dynamically "dot-sources" any `.ps1` script found in the `Functions` folder.
* **Alias:** Creates the `menu` command as a shortcut to the interactive manager.

### 📋 Interactive Menu (`menu`)
By typing `menu` from any directory, you get a high-visibility dashboard:
* **File Explorer:** Displays the contents of your current folder with icons.
* **Function Picker:** Lists all available scripts in your toolkit folder.
* **Execution:** Simply type the number of the script you want to run.

---

## 🛠️ Included Functions

### `mass_rename`
A safe, preview-first renaming tool. 
* **Safety:** Displays a preview of all changes and asks for confirmation (`y/n`) before applying.

### `space_to_dots`
A cleanup utility that replaces all spaces in filenames within the current directory with periods (`.`).

---

## 🎨 Visual Requirements
To see the icons correctly, you must use a **Nerd Font**.
1. Download a font (e.g., *JetBrains Mono Nerd Font*) from [nerdfonts.com](https://www.nerdfonts.com).
2. Install it on Windows.
3. Open Terminal Settings (`Ctrl + ,`) > **Profiles** > **Defaults** > **Appearance** > Set **Font face** to your chosen Nerd Font.

---

## 📂 File Structure

After setup, your files will be organized as follows:

* `Documents\PowerShell\Scripts\` - Contains the main `Menu.ps1`
* `Documents\PowerShell\Scripts\Functions\` - Stores your individual `.ps1` function files.

### ⚖️ License

Distributed under the MIT License. See LICENSE for more information.
