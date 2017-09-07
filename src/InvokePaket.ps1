function Invoke-Paket
{

    Push-Location "$(getProjectRoot)"
    
    BootstrapPaket
    BootstrapDSCModule
    generatePaketFiles

    if(isWindows)
    {
        $paketBin = ".paket\paket.exe"
    }
    else
    {
        $paketBin = "mono .paket\paket.exe"
    }

    Invoke-ExternalCommand $paketBin $args

    clearPaketFiles

    Pop-Location

}