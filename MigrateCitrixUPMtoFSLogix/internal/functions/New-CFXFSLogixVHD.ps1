function New-CFXFSLogixVHD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $citrixProfilePath,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string[]] $Username,

        # FSLogix command line tool path
        [Parameter(Mandatory = $false)]
        [string] $FRX
    )

    if (Test-Path -Path $Path) {
        Write-PSFMessage -Level Verbose -Message "Disk already exists at $Path. Deleting file."
        Remove-Item -Path $Path -Force -Confirm:$false -ErrorAction 'Stop'
    }

    Write-PSFMessage -Level Verbose -Message "Starting copy from '$citrixProfilePath' to '$Path'"
    $copyResults = (& $FRX copy-profile -filename $Path -username $Username -profile-path $citrixProfilePath )

    if($copyResults[-1] -ne 'Operation completed successfully!' ){
        throw ($copyResults | Out-String)
    }
    Write-PSFMessage -Level Verbose -Message "Profile copy from citrix Operation completed successfully!"
}