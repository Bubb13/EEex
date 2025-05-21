@echo off
setlocal

REM /* this initializes the values for the different variables referenced in compatible_games */
call "%~dp0..\ModPackaging\utilities\ie_games.bat"

REM /* MODIFY: set the values of the 3 variables below to reflect the current mod version */
set "mod_name=EEex"
set "mod_version=devel"
set mod_folder=EEex

REM /* MODIFY: list here which IE games the mod is compatible with, from this list of possibilities: */
REM /* %bg1%, %bg2%, %bgt%, %tutu%, %bgee%, %bgiiee%, %iwd1%, %iwdee%, %iwd2%, %iwd2ee%, %iwd-in-bg2%, %pst%, %pstee%, %eet% */
set "compatible_games=%bgee%, %bgiiee%, %eet%, or %iwdee%"

REM /* MODIFY: these variables have sensible default values but they may need to be tweaked to match your particular mod */
REM /* the ico_folder is where your .ico files are stored, which is usually the mod's backup or style folder */
REM /* the audio_folder is where your sox and oggdec.exe utilities are stored (leave alone if you have no audio) */
REM /* the tispack_folder is the root directory that contains the win32, osx, and unix subfolders where your tisunpack utilities are stored (leave alone if you have no tilesets)  */
REM /* the iconv_folder is where your iconv.exe utility is stored (leave alone if you are not converting charsets for BGEE) */
REM /* the mod_readme link should point to the online readme and work fine as-is if the mod uses the standard G3 naming scheme */
set ico_folder=style
REM set audio_folder=%mod_folder%\audio
REM set tispack_folder=%mod_folder%\tiz
REM set tile2ee_folder=%mod_folder%\tools\tile2ee
REM set iconv_folder=%mod_folder%\languages\iconv
set mod_readme=https://eeex-docs.readthedocs.io/en/latest/Introduction/components.html
set generate_readme=0

REM /* MODIFY: if you don't need to build a specific package, you can disable it by setting the appropriate variable below to 0 */
set build_windows=1
set build_osx=0
set build_linux=0

REM /* MODIFY: if you want to avoid making filenames lowercase, you can disable that by setting the variable below to 0 */
set lowercase_filenames=0

REM /* this performs the actual packaging */
call "%~dp0..\ModPackaging\utilities\complete_packaging.bat"

endlocal
