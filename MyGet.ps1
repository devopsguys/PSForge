param(
    [string] $packageVersion = "",
    [bool] $fakeBuildRunner = $false
)

Import-Module -Force .\PowershellDSCWorkflow.psm1

Export-DSCModule -Version $packageVersion
