function Dismount-CFXProfile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $DiskPath,

        [Parameter(Mandatory = $true)]
        [string] $Cookie,

        [Parameter(Mandatory = $true)]
        [string] $FRX

    )

    $result = & $FRX end-edit-profile -filename $DiskPath -cookie $Cookie
    if($result[-1] -ne 'Operation completed successfully!' ){
        throw ($result | Out-String)
    }
}