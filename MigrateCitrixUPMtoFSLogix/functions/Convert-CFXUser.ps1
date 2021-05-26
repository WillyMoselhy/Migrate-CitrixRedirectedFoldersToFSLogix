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
        [ValidateScript({Get-ADGroup -Identity $_ -ErrorAction Stop})]
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
    }

    process {
        foreach ($user in $Username) {
            try {
                Write-PSFMessage -Level Host -Message "Working on $user"
                #region: Reset Variables
                $sid = $null
                $citrixProfilePath = $null
                $UserRedirectedFoldersPath =$null
                $diskItemLength = $null
                $copyResult = $null
                $errorMessage = $null
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
                $UserRedirectedFoldersPath = Get-CFXProfilePath -Username $user -ProfilePath $RedirectedFoldersPath -ErrorAction Stop
                #If folder not found, fail

                #endregion: Calculate variables

                #region: Validate user is not member of AD Group
                if($ADGroupName){
                    Write-PSFMessage -Level Verbose -Message "Confirming $user is not a member of $ADGroupName"
                    if(Get-ADGroupMember -Identity $ADGroupName | where-Object SamAccountName -eq $user){
                        throw "User: $user is already a member of AD Group: $ADGroupName"
                    }
                }

                #endregion: Validate user is not member of AD Group

                #region: Create disk using FSLogix copy-profile
                $tempDiskPath = Join-PSFPath $TempFolderPath ($fslogixFilePath[0] | Split-Path -Leaf)
                Write-PSFMessage -Level Verbose -Message "Copying Citrix profile to new VHD: $tempDiskPath"
                New-CFXFSLogixVHD -citrixProfilePath $citrixProfilePath -Path $tempDiskPath -Username $user -FRX $FRXPath -ErrorAction Stop

                #endregion: Create disk using FSLogix copy-profile

                #region: Copy redirected folders to disk using robocopy
                Write-PSFMessage -Level Verbose -Message "Copying Redirected folders to VHD."
                Copy-CFXRedirectedFolders -DiskPath $tempDiskPath -RedirectedFoldersPath $UserRedirectedFoldersPath -FRX $FRXPath -ErrorAction Stop
                #endregion: Copy redirected folders to disk using robocopy

                #region: Copy disk to profile location(s)
                $diskItemLength = (Get-Item -Path $tempDiskPath).Length
                Write-PSFMessage -Level Verbose -Message "Copying VHD to FSLogix Providers."
                $copyResult = Copy-CFXFSLogixProvider -DiskPath $tempDiskPath -ProviderPath $fslogixFilePath -SetOwner:$SetFSLogixOwner -SID $sid
                #endregion: Copy disk to profile location(s)

                #region: Add user to AD Group
                if($ADGroupName){
                    Write-PSFMessage -Level Verbose -Message "Adding $user to $ADGroupName"
                    Add-ADGroupMember -Identity $ADGroupName -Members $user -ErrorAction Stop
                }
                #endregion: Add user to AD Group

                $success = $true

            }
            catch {
                $errorMessage = $_
                $success = $false
                Write-PSFMessage -Message "Error" -Level Warning -ErrorRecord $_ -EnableException $true -PSCmdlet $PSCmdlet
                Write-Error $_
            }
            finally {
                # Delete Temp Disk
                if(-Not $DoNoCleanup){
                    Remove-Item -Path $tempDiskPath -Force -ErrorAction Continue
                }

            }

            #return output for the user
            [PSCustomObject]@{
                username              = $user
                Success               = $success
                SID                   = $sid
                CitrixProfilePath     = $citrixProfilePath
                RedirectedFoldersPath = $UserRedirectedFoldersPath
                VHDSizeGB             = $diskItemLength
                CopyResults           = $copyResult
                ErrorMessage          = $errorMessage
            }
        }
    }
}