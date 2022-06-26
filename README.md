<h1>Overview:</h1>
EEex is an executable extender for Beamdog's Enhanced Edition of the Infinity Engine. Its goal is to externalize certain parts of the engine to grant modders a greater degree of control over otherwise hardcoded mechanics. EEex does <b class="Bold">not</b> make any gameplay changes itself - it merely enables other mods to do so.
<br>

<h1>Download:</h1>
Alpha versions of this project are now available on <a href="https://github.com/Bubb13/EEex/releases">GitHub</a>.

<br><b><i>The current alpha version only supports Windows platforms, however, MacOS and Linux support is planned for release.</i></b>
<br>
<br>
Supported game versions include:
<br>
BG:EE v2.6.6.0, BG2:EE v2.6.6.0, and IWD:EE v2.6.6.0 — EEex versions >= v0.9.0-alpha.
<br>
BG:EE v2.5.17.0, BG2:EE v2.5.16.6, and IWD:EE v2.5.17.0 — EEex versions < v0.9.0-alpha.
<br>

<h1>Function:</h1>
EEex uses a loader to modify the game's executable after it has been loaded into memory. The exact modifications made depend on the version of EEex installed, and any installed mods that make use of EEex's capabilities.
<br>
<br>
<b class="Bold">Please note: The following links are NOT intended to be used for installing EEex; the loaders are bundled in their respective EEex versions and will be automatically installed alongside EEex.</b>
<br>
<br>
<a href="https://github.com/Bubb13/InfinityLoader">InfinityLoader</a> — EEex versions >= v0.9.0-alpha.
<br>
<a href="https://github.com/mrfearless/EEexLoader">EEexLoader</a> (thanks mrfearless!) — EEex versions < v0.9.0-alpha.

<h1>Installation:</h1>
EEex is installed just as any other WeiDU mod. Simply extract the archive's contents into your game's base folder, and run the setup - it will take care of the rest. <b class="Bold">
<br>
<br>
Please note: The game must be started using InfinityLoader.exe/EEex.exe after installation; any attempt to start the game using the vanilla executable will result in a crash.
<br>
<br>
If InfinityLoader.exe fails to start, please ensure you have installed the latest <a href="https://aka.ms/vs/17/release/vc_redist.x64.exe/">Microsoft Visual C++ Redistributable</a>.</b>

<br><b class="Bold">Stability:</b> EEex is currently in alpha, and as such the odd crash may occur. If you encounter a crash, please report the issue - stating any installed mods, steps that lead to the crash, and upload the generated crash .dmp.
<br>

<h1>Documentation:</h1>
EEex makes extensive use of the EE Lua environment, with most of its functionality implemented as Lua code. Features include new Lua functions, opcodes, scripting actions, triggers, and objects. Please see the <a href="https://eeex-docs.readthedocs.io/en/latest/">EEex Documentation</a> for an overview of EEex's features.

<br><b class="Bold">The above documentation is a work in progress. If you wish to contribute, visit the <a href="https://eeex-docs.readthedocs.io/en/latest/Community/contributing.html">contributing</a> page for details.</b>
