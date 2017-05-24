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
