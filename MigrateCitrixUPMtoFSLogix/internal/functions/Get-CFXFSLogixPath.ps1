function Get-CFXFSLogixPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $FSLogixProfileRootPath,

        # FSLogix Folder Name Pattern
        [Parameter(Mandatory = $false)]
        [string] $FSLogixFolderPattern,

        # FSLogix VHDX Name Pattern
        [Parameter(Mandatory = $false)]
        [string] $FSLogixVHDXPattern,

        # Username used for logon (SAMAccountName)
        [Parameter(Mandatory = $true)]
        [string] $Username,

        # Active Directory SID of the user
        [Parameter(Mandatory = $true)]
        [string] $SID,

        [Parameter(Mandatory = $false)]
        [switch] $Overwrite
    )
    begin {
        # Calculate Profile Folder name
        $profileFolderName = $FSLogixFolderPattern -replace "%SID%",$SID -replace "%username%",$Username
        if($profileFolderName -like "*%*") {throw "Could replace all maps in ($FSLogixFolderPattern). Please only use %SID% or %Username%."}

        # Calculate profile virtual disk name
        $profileVHDXName = $FSLogixVHDXPattern -replace "%SID%",$SID -replace "%username%",$Username
        if($profileVHDXName -like "*%*") {throw "Could replace all maps in ($FSLogixFolderPattern). Please only use %SID% or %Username%."}
    }
    process{
        $paths = foreach ($provider in $FSLogixProfileRootPath){

            $path = Join-PSFPath $provider $profileFolderName $profileVHDXName
            Write-PSFMessage -Level Verbose -Message "Calculated FSLogix path for $username on $provider as: $path"

            if((Test-Path $path) -and (-Not $Overwrite)){
                throw "FSLogix Disk at '$path' already exists. You can user -OverwriteFSLogix switch to avoid this error."
            }
            $path
        }
        $paths
    }
}