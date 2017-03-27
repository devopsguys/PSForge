param(
    [string] $packageVersion = "",
    [bool] $fakeBuildRunner = $false
)

Import-Module -Force .\PowershellDSCWorkflow.psm1
Invoke-Paket restore

Import-Module -Force .\packages\Plaster\Plaster.psm1

Export-DSCModule -Version $packageVersion
