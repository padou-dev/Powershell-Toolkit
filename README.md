\# 🛠️ PowerShell Core IT Toolkit



A portable, "one-click" deployment script designed to standardize a PowerShell 7 environment across multiple machines. This toolkit automates folder structures, installs visual enhancements, and provides a custom interactive menu for common IT tasks.



> \[!IMPORTANT]

> \*\*Requirements:\*\* This script requires \*\*PowerShell 7+\*\* and \*\*Administrator Privileges\*\* for initial setup.



\---



\## 🚀 Quick Start



1\. Open \*\*PowerShell 7\*\* as Administrator.

2\. Run the `Setup.ps1` script.

3\. \*\*Restart your Terminal.\*\*

4\. Type `menu` to launch the interactive toolkit.



\---



\## 📦 What this Toolkit Does



\### 1. Environment Standardization

The script automatically configures your `$PROFILE` (the script that runs every time you open PowerShell) with the following:

\* \*\*Terminal-Icons:\*\* Adds file-type icons to your directory listings.

\* \*\*PSReadLine:\*\* Optimized for efficiency with `MenuComplete` enabled on the \*\*Tab\*\* key.

\* \*\*Auto-Loader:\*\* Dynamically "dot-sources" any `.ps1` script found in the toolkit folder, making your custom functions available immediately by name.

\* \*\*Alias:\*\* Creates the `menu` command as a shortcut to the interactive manager.



\### 2. Interactive Menu (`menu`)

By typing `menu` from any directory, you get a high-visibility dashboard:

\* \*\*File Explorer:\*\* Displays the contents of your current folder with icons.

\* \*\*Function Picker:\*\* Lists all available scripts in your `Documents\\PowerShell\\Scripts\\Functions` folder.

\* \*\*Execution:\*\* Simply type the number of the script you want to run.



\---



\## 🛠️ Included Functions



\### `mass\_rename`

A safe, preview-first renaming tool. 

\* \*\*How it works:\*\* Prompts for a specific string to find and a string to replace.

\* \*\*Safety:\*\* It displays a preview of all changes and asks for confirmation (`y/n`) before touching any files on disk.



\### `space\_to\_dots`

A cleanup utility for terminal-friendly filenames.

\* \*\*How it works:\*\* Replaces all spaces in filenames within the current directory with periods (`.`). 

\* \*\*Use Case:\*\* Perfect for preparing files for web hosting or Linux-based environments where spaces cause syntax issues.



\---



\## 🎨 Visual Requirements

To see the icons correctly, you must use a \*\*Nerd Font\*\*.

1\. Download a font (e.g., \*JetBrains Mono Nerd Font\*) from \[nerdfonts.com](https://www.nerdfonts.com).

2\. Install it on Windows.

3\. Open Terminal Settings (`Ctrl + ,`) > \*\*Profiles\*\* > \*\*Defaults\*\* > \*\*Appearance\*\* > Set \*\*Font face\*\* to your chosen Nerd Font.



\---



\## 📂 File Structure

After setup, your files will be organized as follows:

\* `Documents\\PowerShell\\Scripts\\` - Contains the main `Menu.ps1`

\* `Documents\\PowerShell\\Scripts\\Functions\\` - Stores your individual `.ps1` function files.

