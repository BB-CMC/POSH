# #############################################################################
# NAME: SetStart.ps1
#
# AUTHOR:	Brandon Burkhardt
# DATE:		2020/9/25
# EMAIL:	Brandon.Burkhardt@cmcmaterials.com
#
# COMMENT:  Script to auto-reformat start menu - No Admin credentials needed.
#           
#
# REQUIRE:  Permission to modify folder and folder contents at the user level.
# USAGE:    .\SetStart.ps1
# #############################################################################
#----------------------------------------------------------------#
#v#v#v# BEGIN SCRIPT #v#v#v#
#----------------------------------------------------------------#
# Catch the exception for script execution policy.
#----------------------------------------------------------------#
# Set Error action preference
#----------------------------------------------------------------#
$ErrorActionPreference = "SilentlyContinue"
#----------------------------------------------------------------#
Try
{
    Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
}
Catch
[Exception]{
$ErrorActionPreference
}
#----------------------------------------------------------------#
#Initial Declarations & Imports.
#----------------------------------------------------------------#
$User = WhoAmI
$Uzer = $User.Replace("cmc\", "")
#----------------------------------------------------------------#
#^# End Declarations #^#^#
#----------------------------------------------------------------#
#V#V# Begin Unpinning Start Menu #V#V#
#----------------------------------------------------------------#
#Necessary DLL's imported to unpin all icons from stock/default start menu after newly imaged.
#----------------------------------------------------------------#
$getstring = @'
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    internal static extern int LoadString(IntPtr hInstance, uint uID, StringBuilder lpBuffer, int nBufferMax);

    public static string GetString(uint strId) {
        IntPtr intPtr = GetModuleHandle("shell32.dll");
        StringBuilder sb = new StringBuilder(255);
        LoadString(intPtr, strId, sb, sb.Capacity);
        return sb.ToString();
    }
'@
$getstring = Add-Type $getstring -PassThru -Name GetStr -Using System.Text
$unpinFromStart = $getstring[0]::GetString(51394)
#----------------------------------------------------------------#
#Shell application function that unpins ALL apps from start menu
#----------------------------------------------------------------#
$unShell = (New-Object -Com Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}").Items() | ForEach { $_.Verbs() | Where {$_.Name -eq $unpinFromStart} | ForEach {$_.DoIt()}}
Write-Host "Start apps unpinned."
#----------------------------------------------------------------#
#^#^# End Start Menu Unpinning #^#^#
#----------------------------------------------------------------#
#V#V# Begin Start Menu Pinning #V#V#
#----------------------------------------------------------------#
#Copy desired apps/shortcuts from their source to the start menu destination for parsing.
#----------------------------------------------------------------#
#MS Office Apps:
#----------------------------------------------------------------#
Try {
    Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" 
    Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" 
    Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs" 
    Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Skype for Business.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
    }
Catch [Microsoft.PowerShell.Commands.CopyItemCommand] 
    {
    $ErrorActionPreference
    }
Finally 
    {
    $msExist = @(
        Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk"
        Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk"
        Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk"
        Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk"
        Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Skype for Business.lnk"
        )
        if ($msExist -eq $false) 
        {
            Write-Warning -Message "MS Office not yet installed."
        }
        elseif ($msExist -eq $true) 
        {
            Write-Host "Copying MSO to destination..."
        }
        
    }
#----------------------------------------------------------------#
#Other Apps:
#----------------------------------------------------------------#
Copy-Item -Path "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Endpoint Manager\Configuration Manager\Software Center.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
#----------------------------------------------------------------#
#Apps copied for XML purposes:
#----------------------------------------------------------------#
Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cisco\Cisco AnyConnect Secure Mobility Client\Cisco AnyConnect Secure Mobility Client.lnk" -Destination "C:\Users\$Uzer\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
#----------------------------------------------------------------#
#Shell for shortcut (.lnk) types - used to parse the apps as part of the pinning to start menu process.
#----------------------------------------------------------------#
if ($msExist -eq $true) 
{
    $shell = New-Object -ComObject "Shell.Application"
    $folder = $shell.Namespace("C:\ProgramData\Microsoft\Windows\Start Menu\Programs")
    $items = @(
        $folder.Parsename("Word.lnk"),
        $folder.ParseName("Excel.lnk"),
        $folder.ParseName("PowerPoint.lnk"),
        $folder.ParseName("Skype for Business.lnk")
        )
    #----------------------------------------------------------------#
    #Verb section that actually does the act of pinning to the start menu.
    #----------------------------------------------------------------#
    $verb = $items.Verbs() | Where-Object {$_.Name -eq '&Pin to Start'}
    if ($verb) 
        {
        $verb.DoIt()
        }
    Write-Host "MSO apps pinned to start."
}
#----------------------------------------------------------------#
#Shell for executable (.exe) types to pin to start menu.
#----------------------------------------------------------------#
$secondShell = New-Object -ComObject "Shell.Application"
$pinIE = $secondShell.NameSpace("C:\Program Files\internet explorer\")
$pinVPN = $secondShell.NameSpace("C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\")
$sItems = @( 
    $pinIE.ParseName("iexplore.exe"),
    $pinVPN.ParseName("vpnui.exe")
    )
#----------------------------------------------------------------#
#Verb section for actual pinning of .exe to the start menu.
#----------------------------------------------------------------#
$sVerb = $sItems.Verbs() | Where-Object {$_.Name -eq '&Pin to Start'}
if ($sVerb) 
    {
    $sVerb.DoIt()
    }
Write-Host "Internet Explorer and VPN pinned to start"
#----------------------------------------------------------------#
#^#^# End Start Menu Pinning #^#^#
#----------------------------------------------------------------#
#V#V# Secondary Operations #V#V#
#----------------------------------------------------------------#
#Delete Edge shortcut on stock desktop.
#----------------------------------------------------------------#
$remEdge = Remove-Item -Path "C:\Users\$Uzer\Desktop\Microsoft Edge.lnk" -Force
Start-Sleep -Seconds 1
$edgeRem = Test-Path -Path "C:\Users\$Uzer\Desktop\Microsoft Edge.lnk"
if ($edgeRem -eq $false) 
{
Write-Host "Edge shortcut deleted, refreshing explorer."
}
Start-Sleep -Seconds 1
Stop-Process -Name explorer
Start-Sleep -Seconds 2
#----------------------------------------------------------------#
#Since Software Center is a pointer to an intranet location, it cannot be pinned to start/taskbar with a script - so makes Desktop icon instead. 
#----------------------------------------------------------------#  
$softShortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Endpoint Manager\Configuration Manager\Software Center.lnk"
$targetShortcut = "C:\Users\$Uzer\Desktop\Software Center.lnk"
$shortShell = New-Object -ComObject WScript.shell
$swShortcut = $shortShell.CreateShortcut($targetShortcut)
$swShortcut.TargetPath = $softShortcut
$swShortcut.Save()
$scShortcutExists = Test-Path "C:\Users\$Uzer\Desktop\Software Center.lnk"
if ($scShortcutExists -eq $true) 
{
Write-Host "Software Center Shortcut created."
}
Write-Host "Done!"
#----------------------------------------------------------------#
#Currently, running the Import-StartLayout for customizing taskbar requires admin but with admin, group policy forbids script execution.
#----------------------------------------------------------------#
#Import-StartLayout -LayoutPath "C:\Users\$Uzer\Desktop\taskbar.xml" -MountPath "C:\"
#----------------------------------------------------------------#
#^#^# End Secondary Operations #^#^#
#----------------------------------------------------------------#
#V#V# Begin User Setup Operations #V#V#
#----------------------------------------------------------------#
#Launch OneDrive and Outlook for sign in.
#----------------------------------------------------------------#
$outlook = Start-Process -FilePath "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
$onedrive = Start-Process -FilePath "C:\Users\$Uzer\AppData\Local\Microsoft\OneDrive\OneDrive.exe"
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