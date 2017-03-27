param(
    [string] $packageVersion = $env:PackageVersion,
    [bool] $fakeBuildRunner = $false
)


Invoke-Expression ".\paket restore -f"

Import-Module -Force .\PowershellDSCWorkflow.psm1
Import-Module -Force .\packages\Plaster\Plaster.psm1

Export-DSCModule -Version $packageVersion
