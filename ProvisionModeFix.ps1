Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false

# Below command fixes PCs stuck in Provisioning mode (In-place upgrade/other TS don't populate in Software Center).
Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name SetClientProvisioningMode -ArgumentList $true

Write-Warning "PC must be rebooted to complete repairs!"
$reboot = Read-Host -Prompt "Reboot now? (Y/N)"

if ($reboot -like "Y") {
    Shutdown /r -t 00
    }
elseif ($reboot -like "N") {
    Write-Warning "Reboot postponed; Software Center will not be available until after reboot."
    Start-Sleep -Seconds 3
    Exit
}