@echo off
echo Signing Installer File
echo CERTFILE=%CERTFILE%
for %%f in (.\FLIMfitStandalone\Installer\*) do "C:\Program Files (x86)\Windows Kits\10\bin\x86\signtool" sign /debug /v /f "%CERTFILE%" /p "%CERTPASS%" /n "Sean Warren" /tr http://timestamp.globalsign.com/?signature=sha2 /td sha256 "%%f"