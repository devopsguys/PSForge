function Invoke-PlasterWrapper {
    param (
        [Parameter(Mandatory=$True,Position=1)]
        $Parameters
    )
    Invoke-Plaster @Parameters -NoLogo *> $null
}