Import-Module ActiveDirectory
$OU = "OU=Live Users,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
$gOU = "OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$lOU = "OU=Infrastructure,OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$ErrorActionPreference = "SilentlyContinue"
$User = whoami
$Uzer = $User.Replace("cmc\", "")
#----------------------------------------------------------------#
#
#----------------------------------------------------------------#
# Enter name and group then get the SamAccountName for user.
#----------------------------------------------------------------#
$empChange = Read-Host -Prompt "Enter/Paste name of account changes are going to be made to"

$userChange = Get-ADUser -Filter {Name -eq $empChange} -Properties Name, `
SamAccountName, MemberOf -SearchBase $OU | Select-Object Name, `
SamAccountName, MemberOf | Sort Name
$userName = $userChange.SamAccountName

$msoGroups = Get-ADGroup -Filter {Name -like "License*"} -SearchBase $lOU | Select-Object Name, SamAccountName
Write-Host $msoGroups.name -Separator `r`n | Format-List 
$addLicense = Read-Host -Prompt "Enter the app name (last word in string) from the list above - Example: Sharepoint"
if ($addLicense -ne $null)
{
    $assign = $msoGroups | Where-Object SamAccountName -Like "*$addLicense"
    if ($assign -ne $null)
    {
        Add-ADGroupMember -Identity $assign.SamAccountName -Members $userName -Confirm:$false
        $adGroups = Get-ADPrincipalGroupMembership -Identity $userName
        ForEach ($group in $adGroups)
        {
            if ($adGroups.Name -contains "License-O365-Cabot-$addLicense")
            {
                Write-Host "Successfully added license."
            }
        }
    }
}