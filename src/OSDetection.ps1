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