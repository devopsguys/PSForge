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
    

    if($PSVersionTable.PSVersion.Major -ge 6) {
      $utf8 = [System.Text.Encoding]::UTF8
    } else {
      $utf8 = "utf8"
    }

    $json | Add-Member NoteProperty $Key $Value -Force
    $json = ConvertTo-Json -depth 100 -InputObject $json
    $json | Out-File $configFile -Encoding $utf8

}