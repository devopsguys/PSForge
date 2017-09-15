function getOSPlatform{
    return [Environment]::OSVersion.Platform
}

function isWindows
{
    return (getOSPlatform) -like "Win*"
}

function isUnix
{
    return (getOSPlatform) -eq "Unix"
}

function isLinux {
    param(
        [string]$Variable = "IsLinux"
    )

    if(Test-Path Variable:\$Variable){
        return getVariableFromString -Name $Variable
    }
    return $false
}

function isOSX {
    param(
        [string]$Variable = "IsOSX"
    )

    if(Test-Path Variable:\$Variable){
        return getVariableFromString -Name $Variable
    }
    return $false
}

function getVariableFromString {
    param(
        $Name
    )
    return (Variable | ? {$_.Name -eq $Name }).Value
}