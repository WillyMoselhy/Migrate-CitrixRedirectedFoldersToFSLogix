function Get-CFXADUserSID {
    [CmdletBinding()]
    param (
        # Username used for logon (SAMAccountName)
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Username
    )

    process {
        try{
            $adUser = Get-ADUser -Identity $Username -ErrorAction Stop
        }
        catch {
            throw
        }
        Write-PSFMessage -Level Verbose -Message "Resolved SID for $username as $($adUser.SID)"
        $adUser.SID
    }
}