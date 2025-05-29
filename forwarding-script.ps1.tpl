# Enable IP forwarding on Windows
Set-NetIPInterface -Forwarding Enabled -InterfaceAlias "Ethernet"

# Ensure firewall allows traffic on forwarded ports
netsh advfirewall firewall add rule name="Allow Port Forwarding" dir=in action=allow protocol=TCP localport=ANY

# Parse IP forwarding rules from metadata
$rules = ConvertFrom-Json '${ip_forwarding_targets}'

foreach ($rule in $rules) {
  Write-Output "Adding port forwarding rule: Listen $($rule.port) → $($rule.ip):$($rule.port)"
  netsh interface portproxy add v4tov4 listenport=$($rule.port) listenaddress=0.0.0.0 connectport=$($rule.port) connectaddress=$($rule.ip)
}

# Restart services to apply changes
Restart-Service WinNat -Force
Restart-Service iphlpsvc -Force

# Wait and log output
Start-Sleep -Seconds 30
netsh interface portproxy show all | Out-File C:\portproxy.log
