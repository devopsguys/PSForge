Describe "Compare-Array" {
    
    . $PSScriptRoot\PesterHelpers.ps1

    It "Should return true if arrays are identical" {
        $val1 = @("a","b","c")
        $val2 = @("a","b","c")
        Compare-Array $val1 $val2 | Should be $True
    }

    It "Should return false if arrays are different" {
        $val1 = @("a","b","c")
        $val2 = @("c","d","e")
        Compare-Array $val1 $val2 | Should be $False
    }

    It "Does not currently support unsorted array matching" {
        $val1 = @("a","b","c")
        $val2 = @("a","c","b")
        Compare-Array $val1 $val2 | Should be $False
    }
}