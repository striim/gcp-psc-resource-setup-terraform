#!/bin/bash
set -euo pipefail

# Log to both console and syslog
exec > >(tee -a /var/log/port-forwarding-init.log | logger -t ip-forwarding) 2>&1

echo "🔧 Starting Linux IP Forwarding Setup..."

# Enable IP forwarding (runtime)
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Enable IP forwarding (persistent)
grep -q "net.ipv4.ip_forward" /etc/sysctl.conf \
  && sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf \
  || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# Install iptables-persistent and jq if not installed
echo "📦 Installing iptables-persistent and jq..."
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent jq

# Determine primary source IP for SNAT
SOURCE_IP=$(ip route get 1 | awk '{print $7}' | head -1)
echo "📡 Detected source IP: $SOURCE_IP"

# Apply dynamic port forwarding rules
echo "⚙️  Applying port forwarding rules..."

RULES_JSON='${ip_forwarding_targets}'
echo "$RULES_JSON" | jq -c '.[]' | while read -r rule; do
  ip=$(echo "$rule" | jq -r '.ip')
  port=$(echo "$rule" | jq -r '.port')
  echo "→ Forwarding TCP port $port to $ip:$port"
  iptables -t nat -A PREROUTING  -p tcp --dport "$port" -j DNAT --to-destination "$ip:$port"
  iptables -t nat -A POSTROUTING -p tcp -d "$ip" --dport "$port" -j SNAT --to-source "$SOURCE_IP"
done

# Save iptables rules
echo "💾 Saving iptables rules for persistence..."
iptables-save > /etc/iptables/rules.v4

echo "✅ IP forwarding and NAT setup complete!"