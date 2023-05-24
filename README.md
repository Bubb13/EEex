# ![EEex Logo](EEex.png)
<h1>Overview</h1>
EEex is an executable extender for Beamdog's Enhanced Edition of the Infinity Engine. Its goal is to externalize certain parts of the engine to grant modders a greater degree of control over otherwise hardcoded mechanics.
<br>
<br>
EEex's core component does <b>not</b> make any gameplay changes itself – it merely enables other mods to do so. The installer provides additional <a href="https://eeex-docs.readthedocs.io/en/latest/Introduction/components.html">components</a> that make gameplay changes.

<h1>Compatibility</h1>
Operating systems:
<br>
<br>

- Windows — Yes (native)
- Linux — Proton / Wine with the appropriate option toggled in InfinityLoader.ini
- MacOS — Wine? (untested)

Game versions:

- BG:EE v2.6.6.0, BG2:EE v2.6.6.0, and IWD:EE v2.6.6.0 — EEex versions ≥ v0.9.0-alpha
- BG:EE v2.5.17.0, BG2:EE v2.5.16.6, and IWD:EE v2.5.17.0 — EEex versions < v0.9.0-alpha

Dependencies:

- <a href="https://aka.ms/vs/17/release/vc_redist.x64.exe/">Microsoft Visual C++ Redistributable</a>

<h1>Download</h1>
The latest EEex version can be downloaded from the <a href="https://github.com/Bubb13/EEex/releases">Releases</a> page. The installer is located under the collapsible "Assets" menu.
<br>
<br>
A WeiDU installer has been intentionally omitted from the master branch to prevent it from being accidentally installed, as it contains work-in-progress features and is not guaranteed to be stable.

<h1>Installation</h1>
EEex is distributed as a Gibberlings3 installer. After running the setup file, simply point it to your game directory and click "Install".
<br>
<br>

- Older versions of EEex are distributed without the Gibberlings3 installer. Extract the archive's contents into your game directory and run the setup file to install.

<b>Please note:</b> The game must be started using InfinityLoader.exe / EEex.exe after installation; any attempt to start the game using the vanilla executable will result in a crash. If InfinityLoader.exe fails to start, please ensure you have installed the latest <a href="https://aka.ms/vs/17/release/vc_redist.x64.exe/">Microsoft Visual C++ Redistributable</a>.
<br>
<br>
<b>Stability:</b> While crashes are extremely rare, they may still occur. If you encounter a crash, or a bug with EEex, please report the issue by:
<br>
- Uploading:
  - WeiDU.log — This is in your game directory.
  - A save that exhibits the issue — Saves are found in `C:\Users\<user name>\Documents\<game folder>\save`. Zip the entire save folder.
  - (If applicable) The generated crash .dmp — This is usually found in `C:\Users\<user name>\Documents\Infinity Engine - Enhanced Edition\crash`.
- And:
  - Provide a series of steps that reproduce the issue.

<h1>How EEex works</h1>
EEex uses a loader program to modify the game's executable after it has been placed into memory. The exact modifications depend on the version of EEex, and any installed mods that make use of EEex's capabilities.
<br>
<br>
Due to EEex's use of in-memory patching, antivirus solutions might flag InfinityLoader.exe / EEex.exe as a virus. This is a false positive.
<br>
<br>
<b>Please note:</b> The following links are <b>NOT</b> intended to be used for installing EEex. The loader programs are bundled with EEex and are automatically installed alongside it.
<br>
<br>

- <a href="https://github.com/Bubb13/InfinityLoader">InfinityLoader</a> — EEex versions ≥ v0.9.0-alpha
- <a href="https://github.com/mrfearless/EEexLoader">EEexLoader</a> (thanks mrfearless!) — EEex versions < v0.9.0-alpha

<h1>Documentation</h1>
EEex makes extensive use of the EE Lua environment, with most of its functionality implemented as Lua code. Features include new Lua functions, opcodes, scripting actions, triggers, and objects. Please see the <a href="https://eeex-docs.readthedocs.io/en/latest/">EEex Documentation</a> for an overview of EEex's features.
<br>
<br>
The above documentation is a work in progress. If you wish to contribute, visit the <a href="https://eeex-docs.readthedocs.io/en/latest/Community/contributing.html">contributing</a> page for details.
