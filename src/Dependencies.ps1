function checkDependencies
{
    if(isUnix)
    {
        if(-not (isOnPath "mono"))
        {
            throw New-Object System.Exception ("PSForge has a dependency on 'mono' on Linux and MacOS - please install mono via the system package manager.")
        }
    }

    if(-not (isOnPath "ruby"))
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'ruby' 2.3 or higher - please install ruby via the system package manager.")
    }

    if(-not (isOnPath "git"))
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'git' - please install git via the system package manager.")
    }

    [string]$longRubyVersion = (Invoke-ExternalCommand "ruby" @("--version")).split(' ')[1]
    [double]$shortRubyVersion = ($longRubyVersion.split('.')[0,1]) -join '.'

    if($shortRubyVersion -lt 2.3)
    {
        throw New-Object System.Exception ("PSForge has a dependency on 'ruby' 2.3 or higher. Current version of ruby is ${longRubyVersion} - please update ruby via the system package manager.")
    }

}

function installRuby
{	
    if(isWindows)
    {
        $RubyPath = "$PSScriptRoot\ruby-2.3.3-i386-mingw32\bin\"
        addToPath $RubyPath
        if(-not (Test-Path "$RubyPath\ruby.exe"))
        {
            $Activity = "Installing Ruby"
            $rubyURL = "https://dl.bintray.com/oneclick/rubyinstaller/ruby-2.3.3-i386-mingw32.7z"
            $rubyInstaller = "$PSScriptRoot\ruby.7z"
            Write-Progress -Activity $Activity -Status "Downloading Ruby archive" -percentComplete 20
            Invoke-WebRequest -Uri $rubyURL -OutFile $rubyInstaller 
            Write-Progress -Activity $Activity -Status "Extracting Ruby archive" -percentComplete 60
            Invoke-ExternalCommand $PSScriptRoot\7zip\7za.exe @("x", "$rubyInstaller", "-o""${PSScriptRoot}""") | Out-Null
            Write-Progress -Activity $Activity -percentComplete 100 -Completed
            Remove-Item $rubyInstaller
            fixRubyCertStore
        }
    }else{
        Write-Output "Using system ruby on non-windows platforms"
    }
}

function fixRubyCertStore {
    if(isWindows){
        $SSL_DIR = "C:\RUBY_SSL"
        $CA_FILE = "cacert.pem"
        $CA_URL = "https://curl.haxx.se/ca/${CA_FILE}"
        
        New-Item -Type Directory -Force $SSL_DIR
        
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
        
        [Environment]::SetEnvironmentVariable("SSL_CERT_FILE", "${SSL_DIR}\${CA_FILE}", "User")
        $Env:SSL_CERT_FILE = [Environment]::GetEnvironmentVariable("SSL_CERT_FILE", "User")
        
        (New-Object System.Net.WebClient).DownloadFile($CA_URL, "${SSL_DIR}\${CA_FILE}")
        
        Write-Output "Latest ${CA_FILE} from ${CA_URL} has been downloaded to ${SSL_DIR}"
        Write-Output "Environment variable SSL_CERT_FILE set to $($Env:SSL_CERT_FILE)"
        Write-Output "Ruby for Windows should now be able to verify remote SSL connections"
    }
}

function updateBundle{
    
    if(-not (isOnPath "bundler"))
    {
        Invoke-ExternalCommand "gem" @("install", "bundler") | Out-Null
    }

    $bundle = Start-Process -FilePath "bundle" -ArgumentList "check" -Wait -NoNewWindow -RedirectStandardOutput stdout -PassThru
    Remove-Item stdout
    if($bundle.Exitcode -ne 0)
    {
        Invoke-ExternalCommand "bundle" @("install","--path", ".bundle")
    }
}
function BootstrapDSCModule
{

    $Activity = "Bootstrapping Powershell DSC Module"

    installRuby
    checkDependencies

    if(!(Test-Path ".\.git"))
    {
        Write-Progress -Activity $Activity -Status "Initialising local Git repository" -percentComplete 60
        Invoke-ExternalCommand "git" @("init") | Out-Null
    }

    Write-Progress -Activity $Activity -percentComplete 100 -Completed

}