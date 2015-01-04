@echo off

setlocal
:: Run Texturepacker on all .tps files in the content dir
set texturePackerPath=invalid

:: Check for TexturePacker.exe in ProgramFiles
if exist "%ProgramFiles%\CodeAndWeb\TexturePacker\bin\TexturePacker.exe" (
	set texturePackerPath="%ProgramFiles%\CodeAndWeb\TexturePacker\bin\TexturePacker.exe"
	goto PackTextures
)

:: Check for TexturePacker.exe in ProgramFiles(x86)
if exist "%ProgramFiles(x86)%\CodeAndWeb\TexturePacker\bin\TexturePacker.exe" (
	set texturePackerPath="%ProgramFiles(x86)%\CodeAndWeb\TexturePacker\bin\TexturePacker.exe"
	goto PackTextures
)

if texturePackerPath==invalid (
	echo Could not find TexturePacker.exe
	pause
	goto End
)

:PackTextures
pushd ..\Content
for /f "delims=" %%f in ('dir /b /s /a-d *.tps') do (
  %texturePackerPath% "%%~dpfnxf"
)
popd


:End
endlocal
