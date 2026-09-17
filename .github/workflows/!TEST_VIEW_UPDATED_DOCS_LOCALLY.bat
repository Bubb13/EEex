
@echo off

if not exist ".\EEex-Docs\" (
	git clone https://github.com/Bubb13/EEex-Docs
)

if not exist ".\EEex-Docs\.venv\" (
	python -m venv .\EEex-Docs\.venv\
	attrib +h .\EEex-Docs\.venv
	call .\EEex-Docs\.venv\Scripts\activate.bat
	pip install -r .\EEex-Docs\source\requirements.txt
	pip install -r .\EEex-Docs\source\requirements_dev.txt
) else (
	call .\EEex-Docs\.venv\Scripts\activate.bat
)

java -cp .\java\out\production\java\ UpdateDocs ..\..\EEex\copy\EEex_scripts ".\EEex-Docs\source\EEex Functions"

cd .\EEex-Docs\
call .\make.bat html
start .\build\html\index.html
pause
