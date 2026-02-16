#!/usr/bin/env bash
set -e

VPN_HOST="srcvpn.srcinc.com"

echo "=== SRC VPN Ubuntu Setup Starting ==="
echo "User    : $(whoami)"
echo "Host    : $(hostname)"
echo "Date    : $(date)"
echo

# --------------------------------------------------
# A. Base system prep + Firefox
# --------------------------------------------------
echo "[1/5] Updating system and installing baseline packages (incl. Firefox)..."
sudo apt-get update -y
sudo apt-get install -y \
  curl \
  wget \
  openssl \
  ca-certificates \
  firefox

# --------------------------------------------------
# B. Lighten VM (safe services only)
# --------------------------------------------------
echo "[2/5] Disabling unnecessary services..."

# Disable Bluetooth (safe in Hyper-V)
if systemctl list-unit-files | grep -q '^bluetooth\.service'; then
  sudo systemctl disable --now bluetooth.service || true
  sudo systemctl mask bluetooth.service || true
fi

# Reduce GNOME Tracker indexing (common CPU hog)
if command -v tracker3 >/dev/null 2>&1; then
  tracker3 reset -s || true
fi

# --------------------------------------------------
# C. Trust SRC VPN intermediate certificate (DigiCert)
# --------------------------------------------------
echo "[3/5] Installing SRC VPN intermediate certificate..."

CERT_NAME="DigiCertGlobalG2TLSRSASHA2562020CA1"
CERT_URL="https://cacerts.digicert.com/DigiCertGlobalG2TLSRSASHA2562020CA1.crt"

cd /tmp

echo "Downloading intermediate cert..."
wget -q -O "${CERT_NAME}.crt" "$CERT_URL"

echo "Converting DER -> PEM..."
openssl x509 \
  -inform DER \
  -in "${CERT_NAME}.crt" \
  -out "${CERT_NAME}.pem"

echo "Installing into system trust store..."
sudo cp "${CERT_NAME}.pem" "/usr/local/share/ca-certificates/${CERT_NAME}.crt"

echo "Rebuilding CA store..."
sudo update-ca-certificates --fresh

# --------------------------------------------------
# D. Verification
# --------------------------------------------------
echo "[4/5] Verifying certificate chain to ${VPN_HOST}..."
VERIFY_LINE="$(openssl s_client -connect "${VPN_HOST}:443" -showcerts </dev/null 2>/dev/null | grep -E 'Verify return code' || true)"
echo "${VERIFY_LINE:-'Verify return code not found (unexpected)'}"
echo

# --------------------------------------------------
# E. Cisco Secure Client (manual instructions)
# --------------------------------------------------
echo "[5/5] Cisco Secure Client (manual install)"
echo
echo "1) Download Cisco Secure Client for Linux inside the VM (from corporate portal)."
echo "   Put the file in: ~/Downloads"
echo
echo "2) Install:"
echo "   - If it's a .sh or .run:"
echo "       chmod +x ~/Downloads/<installer>.sh"
echo "       sudo ~/Downloads/<installer>.sh"
echo
echo "   - If it's a .tar.gz bundle:"
echo "       cd ~/Downloads"
echo "       tar xzf <package>.tar.gz"
echo "       cd */vpn  (or locate vpn_install.sh)"
echo "       sudo ./vpn_install.sh"
echo
echo "3) If the UI reports 'VPN service unavailable':"
echo "       sudo systemctl enable vpnagentd.service"
echo "       sudo systemctl start vpnagentd.service"
echo "       systemctl status vpnagentd.service --no-pager"
echo
echo "4) Connect:"
echo "       Server: ${VPN_HOST}"
echo "       Group : Vendors_and_Contractors"
echo
echo "=== SRC VPN Ubuntu Setup Complete ==="
