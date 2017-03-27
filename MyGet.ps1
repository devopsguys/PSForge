param(
    [string] $packageVersion = "",
    [bool] $fakeBuildRunner = $false
)


Invoke-Expression ".\paket restore"

Import-Module -Force .\PowershellDSCWorkflow.psm1
Import-Module -Force .\packages\Plaster\Plaster.psm1

Export-DSCModule -Version $packageVersion
