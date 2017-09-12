Import-Module Plaster

function Invoke-ExternalCommand {
Param(
    [Parameter(Mandatory=$True,Position=1)]
    $command,
    [Parameter(Mandatory=$False,Position=2)]
    $arguments
)
    
    # Reset $result in case it's used somewhere else
    $result = $null

    # Reset $LASTEXITCODE in case it was tripped somewhere
    $Global:LASTEXITCODE = 0

    $result = & $command $arguments 2>$null

    if ($LASTEXITCODE -ne 0) {
        Throw "Something bad happened while executing $command. Details: $($result | Out-String)"
    }

    return $result
}

function Invoke-ExternalCommandRealtime {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        $command,
        [Parameter(Mandatory=$False,Position=2)]
        $arguments
    )

    Invoke-Expression "$command $arguments"
    
}

function GetPSForgeModuleRoot {
    return $PSScriptRoot
}

# Private helper functions
. $PSScriptRoot\src\ModuleInfo.ps1
. $PSScriptRoot\src\OSDetection.ps1
. $PSScriptRoot\src\Dependencies.ps1
. $PSScriptRoot\src\PlasterHelpers.ps1

# Public functions
. $PSScriptRoot\src\NewDSCModule.ps1
. $PSScriptRoot\src\NewDSCResource.ps1
. $PSScriptRoot\src\TestDSCModule.ps1
. $PSScriptRoot\src\ExportDSCModule.ps1
. $PSScriptRoot\src\GetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\SetDSCModuleGlobalConfig.ps1
. $PSScriptRoot\src\InvokePaket.ps1

Export-ModuleMember -function *-*
