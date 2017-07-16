#!/bin/bash

powershell=PowerShell-6.0.0-beta.4-x86_64.AppImage

curl -L https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.4/$powershell -o $powershell

chmod a+x $powershell

./$powershell CI.ps1