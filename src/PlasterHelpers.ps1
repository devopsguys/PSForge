function Invoke-PlasterWrapper {
    param (
        $parameters
    )
    Invoke-Plaster $parameters -NoLogo *> $null
}