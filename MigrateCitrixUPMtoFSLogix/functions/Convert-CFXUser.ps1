function Convert-CFXUser {
    [CmdletBinding()]
    param (
        # Username used for logon (SAMAccountName)
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Username,

        # Location of Citrix Profile for all users e.g. \\FileServer\CTXProfiles\%username%\Win2016\UPM_Profile
        [Parameter(Mandatory = $true)]
        [string] $CitrixUPMProfilePath,

        # Location of Citrix Profile for all users e.g. \\FileServer\RedirectedFolders\%username%
        [Parameter(Mandatory = $true)]
        [string] $RedirectedFoldersPath,

        # Location of FSLogix Profile e.g. \\FileServer\FSLogixProfileContainers\ -  accepts multiple entries.
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string[]] $FSLogixProviderPath,

        # Allow overwrite of existing VHDs when copying to FSLogix providers.
        [Parameter(Mandatory = $false)]
        [Switch] $OverwriteFSLogix,

        # Set the user account as owner on FSLogix VHD and folder.
        [Parameter(Mandatory = $false)]
        [Switch] $SetFSLogixOwner,

        # Set the user account as owner on FSLogix VHD and folder.
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Get-ADGroup -Identity $_ -ErrorAction Stop })]
        [String] $ADGroupName,

        # FSLogix Folder Name Pattern. You can use %SID% or %username%. Default is: "%Username%_%SID%"
        [Parameter(Mandatory = $false)]
        [string] $FSLogixFolderPattern = "%Username%_%SID%",

        # FSLogix virtual disk default size in GB.
        [Parameter(Mandatory = $false)]
        [int] $FSLogixVHDSizeGB = 30,

        # FSLogix VHDX Name Pattern. You can use %SID% or %username%. Default is: "Profile_%Username%.VHDX"
        [Parameter(Mandatory = $false)]
        [ValidatePattern('\.VHDX{0,1}$')] # ErrorMessage = 'FSLogix VHD name must end with VHD or VHDX'
        [string] $FSLogixVHDXPattern = "Profile_%Username%.VHDX",


        # FSLogix command line tool path
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string] $FRXPath = 'C:\Program Files\FSLogix\Apps\frx.exe',

        # Temporary Disk Location - Default is user temp folder $env:Temp
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string] $TempFolderPath = $env:Temp,

        # Robocopy multithread count, default is 100 to maximize copy performance
        [Parameter(Mandatory = $false)]
        [int] $RobocopyMT = 100,

        # Do not delete temp VHD created on temp folder
        [Parameter(Mandatory = $false)]
        [switch] $DoNoCleanup
    )
    begin {
        if ($Username.count -gt 1 `
                -and ($CitrixUPMProfilePath -NotLike "*%username%*") `
                -or ($RedirectedFoldersPath -NotLike "*%username%*")
        ) {
            throw "When providing multiple usernames, you must use %username% in parameters CitrixUPMProfilePath and RedirectedFoldersPath .`r`nFor example: \\FileServer\CTXProfiles\%username%\Win2016\UPM_Profile"
        }
        if ($ADGroupName) {
            try {
                Import-Module -Name ActiveDirectory -ErrorAction Stop
            }
            catch {
                throw "Could not load Active Directory module which is required when -ADGroupName is used."
            }
        }

    }

    process {
        foreach ($user in $Username) {
            try {
                Write-PSFMessage -Level Host -Message "Working on $user"
                #region: Reset Variables
                $sid = $null
                $citrixProfilePath = $null
                $userRedirectedFoldersPath = $null
                $diskItemLength = $null
                $copyResult = $null
                $errorMessage = $null
                $tempDiskCreated = $null
                #endregion: Reset Variables
                #region: Confirm username is correct and retrieve SID
                $sid = Get-CFXADUserSID -Username $user -ErrorAction Stop

                #endregion: Confirm username is correct and retrieve SID

                #region: Calculate variables

                # Calculate name for FSLogix Folder and File - Check if FSLogix folder already exists, fail if so.
                $fsLogixPathParams = @{
                    FSLogixProfileRootPath = $FSLogixProviderPath
                    FSLogixFolderPattern   = $FSLogixFolderPattern
                    FSLogixVHDXPattern     = $FSLogixVHDXPattern
                    Username               = $user
                    SID                    = $sid
                    Overwrite              = $OverwriteFSLogix
                }
                $fslogixFilePath = Get-CFXFSLogixPath @fsLogixPathParams -ErrorAction Stop

                # Calculate path for Citrix profile location
                $citrixProfilePath = Get-CFXProfilePath -Username $user -ProfilePath $CitrixUPMProfilePath -ErrorAction Stop
                #If profile not found, fail

                # Calculate path for Redirected folder profile location
                if ($Username.count -gt 1 -and $CitrixUPMProfilePath -NotLike "*%username%*") {
                    throw "When providing multiple usernames, you must use %username% in parameter RedirectedFoldersPath.`r`nFor example: \\FileServer\RedirectedFolders\%username%"
                }
                $userRedirectedFoldersPath = Get-CFXProfilePath -Username $user -ProfilePath $RedirectedFoldersPath -ErrorAction Stop
                #If folder not found, fail

                #endregion: Calculate variables

                #region: Validate user is not member of AD Group
                if ($ADGroupName) {
                    Write-PSFMessage -Level Verbose -Message "Confirming $user is not a member of $ADGroupName"
                    if (Get-ADGroupMember -Identity $ADGroupName | Where-Object SamAccountName -EQ $user) {
                        throw "User: $user is already a member of AD Group: $ADGroupName"
                    }
                }

                #endregion: Validate user is not member of AD Group

                <# #TODO: DELETE ME!
                #region: Create disk using FSLogix copy-profile

                $tempDiskPath = Join-PSFPath $TempFolderPath ($fslogixFilePath[0] | Split-Path -Leaf)
                Write-PSFMessage -Level Verbose -Message "Copying Citrix profile to new VHD: $tempDiskPath"
                New-CFXFSLogixVHD -citrixProfilePath $citrixProfilePath -Path $tempDiskPath -Username $user -FRX $FRXPath -ErrorAction Stop

                #endregion: Create disk using FSLogix copy-profile
                #>

                #region: Create disk using FSLogix create-vhd
                $tempDiskPath = Join-PSFPath $TempFolderPath ($fslogixFilePath[0] | Split-Path -Leaf)
                Write-PSFMessage -Level Verbose -Message " Create new VHD as: $tempDiskPath"
                New-CFXFSLogixVHD -Path $tempDiskPath -Username $user -FRX $FRXPath -ErrorAction Stop
                $tempDiskCreated = $true
                #endregion: Create disk using FSLogix create-vhd

                #region: Prepare disk and copy redirected folders to disk using robocopy
                Write-PSFMessage -Level Verbose -Message "Mounting VHD using FRX.exe: $tempDiskPath"
                $mountPoint = Mount-CFXProfile -FRX $FRXPath -DiskPath $tempDiskPath

                try {
                    $PrepareDiskError = $null
                    Write-PSFMessage -Level Verbose -Message "Create Profile and Set permissions"
                    Initialize-CFXFSLogixVHD -MountPointPath $mountPoint.Path -SID $sid -ErrorAction Stop

                    $profilePath = Join-PSFPath $mountPoint.Path 'Profile'

                    Write-PSFMessage -Level Verbose -Message "Copying Citrix UPM data"
                    Copy-CFXData -SourcePath $citrixProfilePath -DestinationPath $profilePath -Username $user -DataLabel 'UPMProfile' -RobocopyMT $RobocopyMT -ErrorAction Stop

                    Write-PSFMessage -Level Verbose -Message "Copying Redirected folders to VHD."
                    Copy-CFXData -SourcePath $userRedirectedFoldersPath -DestinationPath $profilePath -Username $user -DataLabel 'RedirectedFolders' -RobocopyMT $RobocopyMT -ErrorAction Stop

                    Write-PSFMessage -Level Verbose -Message "Creating Registry File."
                    New-CFXFSLogixRegText -MountPointPath $mountPoint.Path -Username $user -SID $sid

                }
                catch {
                    $PrepareDiskError = $_
                }
                finally {
                    Write-PSFMessage -Level Verbose -Message "Dismounting VHD using FRX.exe"
                    Dismount-CFXProfile -DiskPath $tempDiskPath -Cookie $mountPoint.Cookie -FRX $FRXPath
                    if ($PrepareDiskError) { throw $PrepareDiskError }
                }

                #endregion: Copy redirected folders to disk using robocopy

                #region: Copy disk to profile location(s)
                $diskItemLength = (Get-Item -Path $tempDiskPath).Length
                Write-PSFMessage -Level Verbose -Message "Copying VHD to FSLogix Providers."
                $copyResult = Copy-CFXFSLogixProvider -DiskPath $tempDiskPath -ProviderPath $fslogixFilePath -SetOwner:$SetFSLogixOwner -SID $sid
                #endregion: Copy disk to profile location(s)

                #region: Add user to AD Group
                if ($ADGroupName) {
                    Write-PSFMessage -Level Verbose -Message "Adding $user to $ADGroupName"
                    Add-ADGroupMember -Identity $ADGroupName -Members $user -ErrorAction Stop
                }
                #endregion: Add user to AD Group

                $success = $true

            }
            catch {
                $errorMessage = $_
                $success = $false
                Write-PSFMessage -Message "Error" -Level Warning -ErrorRecord $_  -PSCmdlet $PSCmdlet
            }
            finally {
                # Delete Temp Disk
                if ((-Not $DoNoCleanup) -and $tempDiskCreated) {
                    Remove-Item -Path $tempDiskPath -Force -ErrorAction Continue
                }

            }

            #return output for the user
            [PSCustomObject]@{
                username              = $user
                Success               = $success
                SID                   = $sid
                CitrixProfilePath     = $citrixProfilePath
                RedirectedFoldersPath = $userRedirectedFoldersPath
                VHDSizeGB             = ($diskItemLength / 1GB)
                CopyResults           = $copyResult
                ErrorMessage          = $errorMessage
            }
        }
    }
}