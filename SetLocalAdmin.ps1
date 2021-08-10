# #############################################################################
# NAME: SetLocalAdmin.ps1
#
# AUTHOR:	Brandon Burkhardt
# DATE:		2020/10/8
# EMAIL:	Brandon.Burkhardt@cmcmaterials.com
#
# COMMENT:  Script to temporarily set your user account as a local admin
#           for certain scripting and other functionalities.
#
# REQUIRE:  Access to a client administrator account.
# USAGE:    .\SetLocalAdmin.ps1
# #############################################################################
#----------------------------------------------------------------#
#v#v#v# BEGIN SCRIPT #v#v#v#
#----------------------------------------------------------------#
# Switch and function to optionally run as administrator.
#----------------------------------------------------------------#
Param([switch]$Elevated)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  
{
    $runAdmin = Read-Host -Prompt "This script must be run as admin, continue? (Y/N)"
    if ($runAdmin -contains "Y") 
    {
        if ($elevated) 
        {
            Write-Host "There was a problem elevating; please close out and try again."
        } 
        else 
        {
            Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
            exit
        }
    }
    elseif ($runAdmin -contains "N") 
    {
        Write-Warning -Message "Elevated privlidges necessary to continue; exciting script."
        Start-Sleep -Seconds 3
        
    }
}

Write-Host "Importing AD module"
Import-Module ActiveDirectory
$ErrorActionPreference = "SilentlyContinue"
$User = whoami
$remdomainUzer = $User.Replace("cmc\", "")
$Uzer = $remdomainUzer.Replace(".client", "")
$daUser = $Uzer + "admin"

$currentLocalAdmins = Get-LocalGroupMember -Group Administrators -Member * | Select ObjectClass, Name, PrincipalSource

if ($currentLocalAdmins.Name -notcontains $Uzer)
{
    Try
    {
        Add-LocalGroupMember -Group Administrators -Member bburkhardt, bburkhardtadmin -Confirm:$false
        Add-LocalGroupMember -Group Administrators -Member $Uzer, $remdomainUzer, $daUser -Confirm:$false
        Write-Host "The following have been made local administrators: $Uzer, $remdomainUzer, $daUser."
        Write-Warning -Message "This should be effective for the next 24 hours, use command: gpupdate /force and reboot to remove sooner or run the SetDefaultAdmin.ps1 script."
    }
    Catch [Exception]
    {
    $ErrorActionPreference
    }
}

#----------------------------------------------------------------#
function Wait-KeyPress
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