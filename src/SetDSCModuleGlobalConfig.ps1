function Set-DSCModuleGlobalConfig
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param (
        [parameter(Mandatory = $true,Position=1)]
        [string] $Key,
        [parameter(Mandatory = $true,Position=2)]
        [string] $Value
    )

    $configFile = "$HOME/DSCWorkflowConfig.json"
    $json = Get-DSCModuleGlobalConfig -NoCheck
    $Key = $Key.ToLower()
    
    $json | Add-Member NoteProperty $Key $Value -Force
    $json = ConvertTo-Json -depth 100 -InputObject $json
    $json | Out-File $configFile -encoding utf8

}