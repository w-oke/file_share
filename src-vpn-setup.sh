#!/usr/bin/env bash
set -e

echo "=== SRC VPN Ubuntu Setup Starting ==="
echo "User    : $(whoami)"
echo "Host    : $(hostname)"
echo "Date    : $(date)"
echo

# --------------------------------------------------
# A. Base system prep
# --------------------------------------------------
echo "[1/5] Updating system and installing baseline packages..."
sudo apt update -y
sudo apt install -y \
  curl \
  wget \
  openssl \
  ca-certificates

# --------------------------------------------------
# B. Lighten VM (safe services only)
# --------------------------------------------------
echo "[2/5] Disabling unnecessary services..."

# Disable Bluetooth (safe in Hyper-V)
if systemctl list-unit-files | grep -q bluetooth.service; then
  sudo systemctl disable --now bluetooth.service || true
fi

# Reduce GNOME Tracker indexing (common CPU hog)
if command -v tracker3 >/dev/null 2>&1; then
  tracker3 reset -s || true
fi

# --------------------------------------------------
# C. Trust SRC VPN intermediate certificate
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
sudo cp "${CERT_NAME}.pem" \
  "/usr/local/share/ca-certificates/${CERT_NAME}.crt"

echo "Rebuilding CA store..."
sudo update-ca-certificates --fresh

# --------------------------------------------------
# D. Verification
# --------------------------------------------------
echo "[4/5] Verifying certificate chain to srcvpn.srcinc.com..."
echo

openssl s_client -connect srcvpn.srcinc.com:443 -showcerts </dev/null \
  | grep -E "Verify return code|CN = DigiCert Global"

# --------------------------------------------------
# C. Install Cisco Secure Client (if present)
# --------------------------------------------------
echo "[5/5] TBC - Checking for Cisco Secure Client installer in ~/Downloads..."

# CISCO_PKG=$(ls ~/Downloads | grep -Ei 'cisco|anyconnect|secure' | head -n 1 || true)

# if [[ -z "$CISCO_PKG" ]]; then
  # echo "⚠️  No Cisco installer found in ~/Downloads. Skipping install."
# else
  # echo "Found Cisco installer: $CISCO_PKG"

  # cd ~/Downloads

  # case "$CISCO_PKG" in
    # *.sh|*.run)
      # chmod +x "$CISCO_PKG"
      # sudo "./$CISCO_PKG"
      # ;;
    # *.tar.gz)
      # tar xzf "$CISCO_PKG"
      # cd */vpn || cd */*vpn* || true
      # sudo ./vpn_install.sh
      # ;;
    # *)
      # echo "⚠️  Unknown Cisco installer format. Install manually if needed."
      # ;;
  # esac
# fi



echo
echo "=== SRC VPN Ubuntu Setup Complete ==="
echo "Next steps:"
echo " - Launch Cisco Secure Client"
echo " - Connect to: srcvpn.srcinc.com"
echo " - Group: Vendors_and_Contractors"