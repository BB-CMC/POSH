# #############################################################################
# NAME: AddGroup.ps1
#
# AUTHOR:	Brandon Burkhardt
# DATE:		2020/9/30
# EMAIL:	brandon_burkhardt@cabotcmp.com
#
# COMMENT:  Script to add a specified user to a specified: 
#           Shared Folder, Group, MSO License, or other License.
#
# REQUIRE:  Permission to read Active Directory object information.
# USAGE:    .\AddGroup.ps1
# #############################################################################
# #V#V#V# BEGIN SCRIPT #V#V#V#
#----------------------------------------------------------------#
# Initial declarations and imports.
#----------------------------------------------------------------#
Import-Module ActiveDirectory
#----------------------------------------------------------------#
# Get DA credential for elevated PS Drive connection.
#----------------------------------------------------------------#
$pushCred = Get-Credential -Message "Enter your DA username and password:"
[pscredential]$cmcCredObj = New-Object System.Management.Automation.PSCredential $pushCred
#----------------------------------------------------------------#
# Connect to PS Drive using Try, Catch, Finally.
#----------------------------------------------------------------#
    Try {
        New-PSDrive -PSProvider FileSystem -Name "GetACL" \\Aurora-F05\DEPARTMENT -Credential $cmcCredObj
        }
    Catch {
        [Exception]
        }
    Finally
        {
        Get-PSDrive -PSProvider FileSystem -Name "GetACL"
        cd GetACL:\
        }
#----------------------------------------------------------------#
# Set OU's and global vars.
#----------------------------------------------------------------#
$OU = "OU=Live Users,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
$gOU = "OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$lOU = "OU=Infrastructure,OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$ErrorActionPreference = "SilentlyContinue"
$User = whoami
$Uzer = $User.Replace("cmc\", "")
#----------------------------------------------------------------#
# If script re-run, clear previously used variables.
#----------------------------------------------------------------#
Try {
    Clear-Variable -Name empChange, userChange, groupAdd, fOrG, theACL, ACL, ownACL, `
    groupPerm, addLicense, aclPermissions
    }
Catch [Exception]{
    $ErrorActionPreference
      }

$pattern = "\\"
#----------------------------------------------------------------#
# Enter name and group then get the SamAccountName for user.
#----------------------------------------------------------------#
$empChange = Read-Host -Prompt "Enter/Paste name of account changes are going to be made to"

$userChange = Get-ADUser -Filter {Name -eq $empChange} -Properties Name, `
SamAccountName, MemberOf -SearchBase $OU | Select-Object Name, `
SamAccountName, MemberOf | Sort Name
$userName = $userChange.SamAccountName

$fOrG = Read-Host -Prompt "Shared Folder (SF), Group (G), MSO License (MSO), or other License (L)?"

if ($fOrG.Contains("SF"))
{
    $aclNeeded = Read-Host -Prompt "Enter the path/folder name specified in the ticket"
    if ($aclNeeded -match "[^A-Z':\']")
    {
        $perfectPath = $aclNeeded
    }
    elseif ($aclNeeded -notmatch "[^A-Z':\']")
    {
    $dirLetter = Read-Host -Prompt "Enter the drive letter (example: N: )"
    

        if ($aclNeeded.Contains($pattern))
        {
            $URI = [URI]$aclNeeded
            $localURI = $URI.LocalPath 
            $pathTrim = $localURI.TrimStart("\\$($URI.host)\")
            $skimPath = $pathTrim.TrimStart("\$($URI.Segments[1])\")
        }
        elseif ($aclNeeded -notcontains $pattern) 
        {
            $skimPath = $aclNeeded
        }
        if ($dirLetter -inotlike '*:')
        {
            $modLetter = $dirLetter + ":\"
            $perfectPath = $modLetter + $skimPath
        }
        elseif ($dirLetter -ilike '*:')
        {
            $modLetter = $dirLetter + "\"
            $perfectPath = $modLetter + $skimPath
        }
        elseif ($dirLetter -ilike '*:\')
        {
            $perfectPath = $dirLetter + $skimPath
        }

        
    $theACL = Get-Acl -Path $perfectPath

    $ACL = $theACL | Select Access | % {$_.Access} | Select FileSystemRights, IdentityReference | FT

    $aclPermissions = $theACL | Select Access | % {$_.Access} | Select IdentityReference

    $ownACL = $theACL | Select Owner | % {$_.Owner}
    $aclOwner = $ownACL.Replace("CMC\", "")

    $textACL = Read-Host -Prompt "Would you like a text document showing folder owner and a list of users with access? [Y/N]"

    if ($textACL -contains "Y")
    {
        "Owner: $aclOwner" >> C:\Users\$Uzer\Desktop\ACL_Info.txt 
        $ACL >> C:\Users\$Uzer\Desktop\ACL_Info.txt 
    }

    ForEach ($acl in $aclPermissions)
    {
        $readOnly = $aclPermissions | Where-Object IdentityReference -like "*RO"
        $readWrite = $aclPermissions | Where-Object IdentityReference -like "*Rw"
    }

    $RO = $readOnly.IdentityReference.Value.TrimStart("CMC\") 
    $RW = $readWrite.IdentityReference.Value.TrimStart("CMC\")

    $groupPerm = Read-Host -Prompt "RO or RW?"

if ($groupPerm.Contains("RO"))
    {
        Add-ADGroupMember -Identity $RO -Members $userName -Confirm:$false
    }
elseif ($groupPerm.Contains("RW"))
    {
        Add-ADGroupMember -Identity $RW -Members $userName -Confirm:$false
    }

  }
}

if ($fOrG.Contains("G"))
{
    $getGroup = Read-Host -Prompt "Enter or paste the name of the group"
    $findGroup = Get-ADGroup -Filter {cn -like $getGroup} -SearchBase $gOU | Select-Object Name, SamAccountName
    if ($findGroup -ne $null)
    {
        Add-ADGroupMember -Identity $findGroup.SamAccountName -Members $userName -Confirm:$false
    }
    elseif ($findGroup -eq $null)
    {
        Write-Warning -Message "No group found with name: $getGroup - please check spelling and try again. Script exiting in 5 seconds."
        Start-Sleep -Seconds 5
        exit
    }
}

if ($fOrG.Contains("MSO"))
{
    $msoGroups = Get-ADGroup -Filter {Name -like "License*"} -SearchBase $lOU | Select-Object Name, SamAccountName
    Write-Host $msoGroups.name -Separator `r`n | Format-List 
    $addLicense = Read-Host -Prompt "Enter the app name (last word in string) from the list above - Example: Sharepoint"
    if ($addLicense -ne $null)
    {
        $assign = $msoGroups | Where-Object SamAccountName -Like "*$addLicense"
        if ($assign -ne $null)
        {
            Add-ADGroupMember -Identity $assign.SamAccountName -Members $userName -Confirm:$false
        }
    }
   
}
#----------------------------------------------------------------#
# Below function can exit or restart script based on key press.
#----------------------------------------------------------------#
function Wait-KeyPress
{
    param
    (
        [string]
        $exitMessage = 'Press Enter to exit.',

        [string]
        $continueMessage = 'Press down arrow to restart script.',

        [ConsoleKey]
        $eKey = [ConsoleKey]::Enter,

        [ConsoleKey]
        $cKey = [ConsoleKey]::DownArrow
    )
    
    Write-Host -Object $exitMessage
    Write-Host -Object $continueMessage
    
    do
    {
        $keyInfo = [Console]::ReadKey($false)
    } 
    until ($keyInfo.Key -eq $ekey -or $cKey)
    if ($keyInfo.Key -eq $ekey)
    {
        cd C:\
        Remove-PSDrive -Name GetACL -Force
        Write-Host "PS Drive removed; disconnected from Aurora-f05."
        Start-Sleep -Seconds 2
        exit
    }
    elseif ($keyInfo.Key -eq $cKey)
    {
        cd C:\
        Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoExit', '-File', """$PSCommandPath""" -NoNewWindow
    }
}
Wait-KeyPress 
#----------------------------------------------------------------#
# #^#^#^# END SCRIPT #^#^#^#
#----------------------------------------------------------------#