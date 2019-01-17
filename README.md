<h1>Overview:</h1>
EEex is an executable extender for Beamdog's Enhanced Edition of the Infinity Engine. Its goal is to externalize certain parts of the engine to grant modders a greater degree of control over otherwise hardcoded mechanics. EEex does <b class="Bold">not </b>make any gameplay changes itself - it merely enables other mods to do so.
<br>

<h1>Just give me the link!</h1>
<b class="Bold">Alpha versions of this project are now available on <a href="https://github.com/Bubb13/EEex/releases">GitHub</a>.</b>

<b class="Bold"><i class="Italic">EEex will support MacOS and Linux on launch, however, the current alpha version only supports Windows. In addition, BG2:EE v2.5.16.6 is the only supported game at the time of writing.</i></b>
<br>

<h1>What does it do?</h1>
EEex, when installed, directly modifies the game's executable in order to insert a loader. This loader is used to alter the game's code on startup; the modifications that are made depend on the version of EEex installed, and any installed mods that make use of EEex's capabilities.
<br>

<h1>I'm a user, what do I need to do to install?</h1>
EEex is installed just as any other WeiDU mod. Simply extract the archive's contents into your game's base folder, and run the setup - it will take care of the rest. <b class="Bold">Please note that since EEex alters the game executable itself, you should ensure that the game is closed before running the installer!</b>

<b class="Bold"><i class="Italic">EEex is currently in alpha, and as such it is highly unstable. All immediate crashes are believed to be fixed, though you still risk a crash at any time. Use with care.</i></b>
<br>

<h1>I'm a modder, how do I use EEex?</h1>
EEex makes changes to many different parts of the engine. Accessing and making use of new opcodes, actions, triggers, and objects is as simple as installing EEex.

The real power of EEex, however, comes from its ability to change hardcoded engine behavior. The hooks that enable these alterations are completely defined and controlled by the Lua environment, and as such, modders wishing to use these systems will have to either:

<b class="Bold">a)</b> Insert a M_*.lua file into the override folder.
<i class="Italic">or</i>
<b class="Bold">b)</b> Edit UI.MENU directly. 

<i class="Italic"><b class="Bold">Detailed documentation pending.</b></i>
<br>
