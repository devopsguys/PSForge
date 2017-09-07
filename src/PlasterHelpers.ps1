function Invoke-PlasterWrapper {
    param (
        [Parameter(Mandatory=$True,Position=1)]
        $PlasterParams
    )

    Invoke-Plaster @PlasterParams -NoLogo *> $null
    
}