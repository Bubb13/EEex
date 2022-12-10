
if exist "./EEex-Docs/" (
	cd ./EEex-Docs/
	git restore .
	git clean -df
	git pull
	cd ..
) else (
	git clone https://github.com/Bubb13/EEex-Docs
)

java -cp ./java/out/production/java/ UpdateDocs ../../EEex/copy "./EEex-Docs/source/EEex Functions"

cd ./EEex-Docs/
call make html
start ./build/html/index.html
pause
