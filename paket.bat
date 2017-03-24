@echo off

if not exist ".\.paket\paket.exe" (
  .\.paket\paket.bootstrapper.exe
)

.\.paket\paket.exe %*
