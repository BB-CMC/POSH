# #############################################################################
# NAME: CMCTerm.ps1
#
# AUTHOR:	Brandon Burkhardt
# DATE:		2020/8/17
# EMAIL:	brandon_burkhardt@cabotcmp.com
#
# COMMENT:  Script to automate the termination process tasks  
#           for CMC domain.
#
# REQUIRE:  Permission to modify Active Directory objects.
# USAGE:    .\CMCTerm.ps1
# #############################################################################

#----------------------------------------------------------------#
#v#v#v# BEGIN SCRIPT #v#v#v#
#----------------------------------------------------------------#
#Initial Declarations & Imports
#----------------------------------------------------------------#
Write-Host "Importing AD module; setting OU variable paths."
Import-Module ActiveDirectory
$ErrorActionPreference = "SilentlyContinue"
$OU = "OU=Live Users,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
$dOU = "OU=Disabled,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
#----------------------------------------------------------------#
#V#V#V# Script Body #V#V#V#
#----------------------------------------------------------------#
# Until integrated with Service Now, need to manually provide name
# of the terminated employee/user.
#----------------------------------------------------------------#
$email = Read-Host -Prompt 'Enter/Paste Email of Terminated Employee'
$tUser = Get-ADUser -Filter {EmailAddress -eq $email} -SearchBase $OU `
-Properties Name, DisplayName, Title, SamAccountName, Description, EmailAddress, `
Enabled, AccountExpirationDate, MemberOf, Office | Select-Object `
Name, DisplayName, Title, SamAccountName, Description, EmailAddress, `
Enabled, AccountExpirationDate, MemberOf, Office | Sort Name
#----------------------------------------------------------------#
# If no account is found, script exits.
#----------------------------------------------------------------#
if ($tUser -eq $null)
{
    Write-Warning -Message "No account with that name was found, `
please check the spelling and try again."
}
#----------------------------------------------------------------#
# Get Date to assign when account was disabled.
#----------------------------------------------------------------#
$dateTime = Get-Date -Format "dddd, MMMM dd, yyyy"
#----------------------------------------------------------------#
# Set user AD objects into an array to loop through.
# Change primary group to "Disabled" and remove all others.
#----------------------------------------------------------------#
$data = @($tUser)
Try
{
    ForEach ($User in $data)
    {
        if ($User.EmailAddress -eq $email)
            {
                $userName = $User.SamAccountName
                $adGroups = Get-ADPrincipalGroupMembership -Identity $userName
                $primaryGroup = Get-ADGroup -Filter "Name -like 'Disabled Users'" -Properties @("primaryGroupToken")
                Add-ADGroupMember -Identity 'Disabled Users' -Members $User.SamAccountName -Confirm:$false
                Set-ADUser -Identity $userName -Replace @{primarygroupid=$primaryGroup.primaryGroupToken} -Confirm:$false 
                Write-Host "Disabled Users set as Primary Group."
                ForEach ($group in $adGroups)
                {
                    if ($group.name -notlike "*Disabled Users*")
                    {
                          Remove-ADGroupMember -Identity $group.name -Members $user.SamAccountName -Confirm:$false
                          Write-Host 'Removed:' $group.name
                    }
                }
            
            }
    }
}
Catch [Exception]
{
$ErrorActionPreference
}
Write-Host "All group memberships removed."
#----------------------------------------------------------------#
<#
# Change Description to: Disabled
# Delete/null E-mail field
# Disable account
# Set account expiration date 
#>
#----------------------------------------------------------------#
$termChanges = Get-ADUser -Identity $userName -Properties Description, EmailAddress, AccountExpirationDate, Enabled, DistinguishedName | ` 
Select-Object Description, EmailAddress, AccountExpirationDate, Enabled, DistinguishedName 

Set-ADUser -Identity $userName -AccountExpirationDate $dateTime -EmailAddress $null -Enabled $false -Description "Disabled" -Confirm:$false

Write-Host "Set account expiration to '$dateTime'"
Write-Host "Email address cleared. `
Description changed to Disabled. `
Account disabled."
#----------------------------------------------------------------#
# Move to Disabled Users OU
#----------------------------------------------------------------#
$distName = $termChanges.DistinguishedName
Move-ADObject -Identity $distName -TargetPath $dOU -Confirm:$false
Write-Host "Moved to Disabled Users OU."
Write-Host -BackgroundColor Green -ForegroundColor DarkRed "Termination complete!"
#----------------------------------------------------------------#
#
#----------------------------------------------------------------#
<#function Wait-KeyPress
{
    param
    (
        [string]
        $exitMessage = 'Press Enter to exit.',


        [ConsoleKey]
        $eKey = [ConsoleKey]::Enter

    )
    
    Write-Host -Object $exitMessage
    
    do
    {
        $keyInfo = [Console]::ReadKey($false)
    } 
    until ($keyInfo.Key -eq $ekey)
    if ($keyInfo.Key -eq $ekey)
    {
        exit
    }
}
Wait-KeyPress
#----------------------------------------------------------------#
#^#^#^# END SCRIPT #^#^#^#
#----------------------------------------------------------------#
#>