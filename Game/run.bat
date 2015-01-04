:: Pack and textures before running
call Scripts\PackTextures.bat

:: run moai
cd GameCode
"../Bin/moai.exe" "main.lua"


pause
