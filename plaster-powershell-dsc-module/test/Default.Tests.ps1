describe 'When setting up a webserver' {
  context 'to start the default website' {

    it 'verifies IIS is installed' {
      (Get-WindowsFeature web-server).installed | should be $true
    }

    it 'installs a default website' {
      Get-Website 'Default Web Site' | should not be $null
    }

  }

}
