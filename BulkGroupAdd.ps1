# #############################################################################
# NAME: BulkGroupAdd.ps1
#
# AUTHOR:	Brandon Burkhardt
# DATE:		2020/12/7
# EMAIL:	brandon.burkhardt@cmcmaterials.com
#
# COMMENT:  Script to add a bulk amount of users to a group/license.         
#
# REQUIRE:  Permission to view/modify Active Directory objects.
# USAGE:    .\BulkGroupAdd.ps1
# #############################################################################
# #V#V#V# BEGIN SCRIPT #V#V#V#
#----------------------------------------------------------------#
# Initial declarations and imports.
#----------------------------------------------------------------#

Import-Module ActiveDirectory
$OU = "OU=Live Users,OU=Users,OU=CMC,DC=cabotcmp,DC=com"
$gOU = "OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$lOU = "OU=Infrastructure,OU=Groups,OU=CMC,DC=cabotcmp,DC=com"
$ErrorActionPreference = "SilentlyContinue"
$User = whoami
$Uzer = $User.Replace("cmc\", "")

#----------------------------------------------------------------#
# Set the path to the CSV.
#----------------------------------------------------------------#

$commonPath = "C:\Users\$Uzer\Desktop\New_User_List.csv"

#----------------------------------------------------------------#
# Confirm on run that file is in proper format and named correctly.
#----------------------------------------------------------------#

$pathTest = Test-Path $commonPath

$fileNamed = Read-Host -Prompt 
If ($pathTest -eq $false) {
    Write-Warning -Message "File not found! Please ensure the user list is in CSV format, on the desktop, and named `"New_User_List.csv`" and try again. Script will now exit."
    Start-Sleep -Seconds 5
    exit
}

#----------------------------------------------------------------#
# Import the users in the CSV.
#----------------------------------------------------------------#

$bulkUsers = Import-Csv -Path $commonPath -Header "PersonName"
$numCSV = $bulkUsers.Count

#----------------------------------------------------------------#
# Get AD User info for each object in the CSV.
#----------------------------------------------------------------#

$bulkInfo = @()
$bulkInfo = $bulkUsers | ForEach-Object {
    $DisplayName = $_.PersonName
    Get-ADUser -Filter {DisplayName -eq $DisplayName} -Properties Name, `
    SamAccountName, MemberOf, DisplayName -SearchBase $OU | Select-Object Name, `
    SamAccountName, DisplayName

}
$numImported = $bulkInfo.Count

if ($numCSV -ne $numImported) {
    $numMissing = $numCSV - $numImported
    Write-Warning -Message "Some users not found using display name! $numMissing users not added to bulkInfo."
    } 

#----------------------------------------------------------------#
# Assign SamAccountName to each object from previous operation.
#----------------------------------------------------------------#

$bulkInfo | ForEach-Object {
    $SM = @()
    $SM = $bulkInfo.SamAccountName
    }
$numUsers = $SM.Count

#----------------------------------------------------------------#
# Check that the number of users imported matches number of SAMs
#----------------------------------------------------------------#
if ($numImported -ne $numUsers) {
    Write-Warning -Message "The amount of users imported does not match the amount of SAM account names!"
}

#----------------------------------------------------------------#
# Query whether assigning license, group, or both.
#----------------------------------------------------------------#

$whatToDo = Read-Host -Prompt "Assign members license [L], add members to group [G], or both [B]?"

if ($whatToDo -contains "L") {
#----------------------------------------------------------------#
# List the available AD licenses and query which to assign.
#----------------------------------------------------------------#

$msoGroups = Get-ADGroup -Filter {Name -like "License*"} -SearchBase $lOU | Select-Object Name, SamAccountName
Write-Host $msoGroups.name -Separator `r`n | Format-List 
$addLicense = Read-Host -Prompt "Enter app name to assign license"

#----------------------------------------------------------------#
# Add/assign each user the desired license.
#----------------------------------------------------------------#

if ($addLicense -ne $null)
{
$assign = $msoGroups | Where-Object SamAccountName -Like "*$addLicense"
    if ($assign -ne $null)
      {
        for ($i = 0; $i -le $numUsers; $i++) {
            $bulkInfo | ForEach-Object {
            Add-ADGroupMember -Identity $assign.SamAccountName -Members $SM.Item($i) -Confirm:$false
            Write-Progress -Activity "Adding license to all members, this will take awhile.." -Status "$numUsers users to add/assign." -PercentComplete ($i / $numUsers * 100)
                }
            }
        }
    } Write-Host "All members assigned $addLicense license."
}

elseif ($whatToDo -contains "G") {

#----------------------------------------------------------------#
# Assign/add each user to desired group.
#----------------------------------------------------------------#

    $adGroup = Read-Host -Prompt "Enter group name to assign"
    $getADGroup = Get-ADGroup -Filter {Name -eq $adGroup} -SearchBase $gOU | Select-Object Name, SamAccountName

    if ($getADGroup -ne $null) {
        for ($f = 0; $f -le $numUsers; $f++) {
            $bulkInfo | ForEach-Object {
                Add-ADGroupMember -Identity $getADGroup.SamAccountName -Members $SM.Item($f) -Confirm:$false
                Write-Progress -Activity "Adding members to group, this will take awhile.." -Status "$numUsers users to add/assign." -PercentComplete ($f / $numUsers * 100)
                }
            }
        } Write-Host "All members added to $adGroup group."
    }

elseif ($whatToDo -contains "B") {

#----------------------------------------------------------------#
# List the available AD licenses and query which to assign.
#----------------------------------------------------------------#

$msoGroups = Get-ADGroup -Filter {Name -like "License*"} -SearchBase $lOU | Select-Object Name, SamAccountName
Write-Host $msoGroups.name -Separator `r`n | Format-List 
$addLicense = Read-Host -Prompt "Enter app name to assign license"

#----------------------------------------------------------------#
# Add/assign each user the desired license.
#----------------------------------------------------------------#

if ($addLicense -ne $null)
{
$assign = $msoGroups | Where-Object SamAccountName -Like "*$addLicense"
    if ($assign -ne $null)
      {
        for ($i = 0; $i -le $numUsers; $i++) {
            $bulkInfo | ForEach-Object {
            Add-ADGroupMember -Identity $assign.SamAccountName -Members $SM.Item($i) -Confirm:$false
            Write-Progress -Activity "Adding license to all members, this will take awhile.." -Status "$numUsers users to add/assign." -PercentComplete ($i / $numUsers * 100)
                }
            }
        } Write-Host "All members assigned $addLicense license."
}
#----------------------------------------------------------------#
# Assign/add each user to desired group.
#----------------------------------------------------------------#
    $adGroup = Read-Host -Prompt "Enter group name to assign"
    $getADGroup = Get-ADGroup -Filter {Name -eq $adGroup} -SearchBase $gOU | Select-Object Name, SamAccountName

    if ($getADGroup -ne $null) {
        for ($f = 0; $f -le $numUsers; $f++) {
            $bulkInfo | ForEach-Object {
                Add-ADGroupMember -Identity $getADGroup.SamAccountName -Members $SM.Item($f) -Confirm:$false
                Write-Progress -Activity "Adding members to group, this will take awhile.." -Status "$numUsers users to add/assign." -PercentComplete ($f / $numUsers * 100)
                }
            }
        } Write-Host "All members added to $adGroup group."
}     
#----------------------------------------------------------------#
# Function to start script over if desired.
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
        Stop-Process -Id $PID -Force
        exit
    }
    elseif ($keyInfo.Key -eq $cKey)
    {
        Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoExit', '-File', """$PSCommandPath""" -NoNewWindow
    }
}
Wait-KeyPress 
#----------------------------------------------------------------#
# #^#^#^# END SCRIPT #^#^#^#
#----------------------------------------------------------------#
