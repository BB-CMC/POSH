  <#
.SYNOPSIS
	Used to uninstall Symantec Antivirus on Windows 7 PCs for in-place upgrade to Windows 10.
   
.NOTES
    Can only be used on Windows 7.

.AUTHOR
    Brandon Burkhardt
    
.CONTACT
    Brandon.Burkhardt@cmcmaterials.com
#>
  
# Import DLL assemblies for Window detection/control.
$sig = @"
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(IntPtr sClassName, String sAppName);
  [DllImport("kernel32.dll")] public static extern uint GetLastError();
  [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
"@

# Get uninstall string from registry.
$computer = hostname
$regCU = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$regLM = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$regWoW = "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

$installed = @()
$installed = Get-ChildItem -Path HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, `
HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Select-Object -Property DisplayName, UninstallString | Sort DisplayName -ErrorAction SilentlyContinue

$av_Uninstall = $installed -like "*Symantec*"
$get_String = $av_Uninstall | Where-Object {$_ -like "*MsiExec.exe*"}

$trim1 = $get_String.TrimStart("@{DisplayName=Symantec Endpoint Protection; UninstallString=")
$trim2 = $trim1.Replace("}}", "}")

$swap_I = $trim2.Replace("/I", "/X")

# Run uninstall to get admin password window to pop up - can take up to 20 seconds. 
$uninstallString = "MsiExec.exe /X{F90EEB64-A4CB-484A-8666-812D9F92B37B}" 
if ($swap_I -ne $uninstallString) {
    start-process cmd.exe -ArgumentList "/c $swap_I /norestart" -PassThru
    }
elseif ($swap_I -eq $uninstallString) {
    start-process cmd.exe -ArgumentList "/c $uninstallString /norestart" -PassThru
    }

Start-Sleep -Seconds 5

# Use Win32 to find window by name and WindowAPI to bring it to foreground
$type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
$fw = Add-Type -Namespace Win32 -Name Funcs -MemberDefinition $sig -PassThru
$ruSure ='Windows Installer' 
$uwindow = $fw::FindWindow([IntPtr]::Zero, $ruSure)
$a = $fw::GetLastError()

$type::SetForegroundWindow($uwindow)
Start-Sleep -Seconds 1
[System.Windows.Forms.SendKeys]::SendWait("Y") #"press" enter key
Start-Sleep -Seconds 60

$wname='Please enter the uninstall password:' # window name for symantec (but can be used for any window name)
$hwnd = $fw::FindWindow([IntPtr]::Zero, $wname ) # returns the Window Handle
$b = $fw::GetLastError()

# Password to send to Symantec uninstall window.
$sendString = "cmcadm1n1"

$type::SetForegroundWindow($hwnd) #bring uninstall window to focus

Start-Sleep -Seconds 3

[System.Windows.Forms.SendKeys]::SendWait("$sendString") #send password to window

start-sleep -Seconds 3

[System.Windows.Forms.SendKeys]::SendWait("{ENTER}") #"press" enter key