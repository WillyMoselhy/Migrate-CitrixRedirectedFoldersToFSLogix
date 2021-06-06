function New-CFXFSLogixVHD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)] #TODO: If we remove the new feature then this should be set to true
        [string] $citrixProfilePath,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string[]] $Username,

        # FSLogix command line tool path
        [Parameter(Mandatory = $false)]
        [string] $FRX,

        # FEATURE SWITCH #TODO: Remove feature switch one complete
        [Parameter(Mandatory = $false)]
        [Switch] $NoProfileCopy =$true
    )
    if (Test-Path -Path $Path) {
        Write-PSFMessage -Level Verbose -Message "Disk already exists at $Path. Deleting file."
        Remove-Item -Path $Path -Force -Confirm:$false -ErrorAction 'Stop'
    }

    if($NoProfileCopy){
        # Got help here from https://xenit.se/tech-blog/convert-citrix-upm-to-fslogix-profile-containers/ , Fernando Martins ,and Jim Moyle
        Write-PSFMessage -Level Verbose -Message "NoProfileCopyEnabled" #TODO: Remove this once feature switch removed

        Write-PSFMessage -Level Verbose -Message "Creating new profile disk using for $username at $Path"
        $newDisk = & $FRX create-vhd -filename $Path -label "FSLogix_$username"
        if($newDisk[-1] -ne 'Operation completed successfully!' ){
            throw ($newDisk | Out-String)
        }
    }
    else{ #TODO: REmove this once feature switch removed.


        Write-PSFMessage -Level Verbose -Message "Starting copy from '$citrixProfilePath' to '$Path'"
        $copyResults = (& $FRX copy-profile -filename $Path -username $Username -profile-path $citrixProfilePath )

        if($copyResults[-1] -ne 'Operation completed successfully!' ){
            throw ($copyResults | Out-String)
        }
        Write-PSFMessage -Level Verbose -Message "Profile copy from citrix Operation completed successfully!"
    }

}