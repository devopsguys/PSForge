function Export-DSCModule
{
param
(
    [parameter(Mandatory = $true,Position=1)]
    [string]$Version
)
    Push-Location "$(getProjectRoot)"

    BootstrapDSCModule
    Invoke-Paket update
    Invoke-Paket pack output .\output version $version

    Pop-Location
}
