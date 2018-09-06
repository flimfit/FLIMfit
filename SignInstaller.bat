@echo off
echo Signing Installer File
for %%f in (.\FLIMfitStandalone\Installer\*) do scsigntool -pin %SMARTCARDPIN% sign /debug /v /n "Sean Warren" /tr http://timestamp.globalsign.com/?signature=sha2 /td sha256 "%%f"
