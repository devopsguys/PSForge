# http://www.indented.co.uk/2014/04/02/compare-array/
function Compare-Array {
    $($args[0] -join ",") -eq $($args[1] -join ",")
}