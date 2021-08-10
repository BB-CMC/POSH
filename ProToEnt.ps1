Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Confirm:$false -Force


$ErrorActionPreference = "SilentlyContinue"


$poshDir = Test-Path "C:\POSH"
if ($poshDir -eq $false) {

mkdir -Path "C:\POSH"
New-Item -Path "C:\POSH\ProToEnt_log.txt"
}

$logFile = "C:\POSH\ProToEnt_log.txt"

Function Write-Log {
    Param ([string]$logstring)

    $logTime = (Get-Date -Format MM-dd-yyy) + "|" + (Get-Date -Format HH:MM:ss:tt)

    Add-Content $logFile -Value ($logTime + " - " + $logstring) 
}

$winEdition = (Get-WmiObject -class Win32_OperatingSystem).Caption
$productKey = "KKBQN-X992K-GMP7H-8XFBH-FJRCF"

if ($productKey -ne $null) {

    start-process c:\Windows\System32\changePK.exe -ArgumentList "/ProductKey $ProductKey"
    Powershell.exe Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name SetClientProvisioningMode -ArgumentList $false
}


