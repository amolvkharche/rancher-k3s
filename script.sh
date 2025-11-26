#!/bin/bash

set -e

echo "Starting Rancher installation script..."

echo "--- Step 1: Installing K3s (Lightweight Kubernetes) ---"
read -p "Enter desired K3s version (e.g., v1.30.1+k3s1, leave empty for latest): " K3S_VERSION

if [ -z "$K3S_VERSION" ]; then
    echo "Installing latest stable K3s version..."
    curl -sfL https://get.k3s.io | sh -
else
    echo "Installing K3s version: $K3S_VERSION..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -
fi


echo "Setting up kubeconfig for the current user..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER":"$USER" ~/.kube/config
chmod 600 ~/.kube/config
echo "Kubeconfig set up successfully."

echo "Waiting for K3s nodes to be ready..."
until sudo kubectl get nodes -o "custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?(@.type==\"Ready\")].status" | grep -q "True"; do
    echo "Waiting for K3s nodes to be ready..."
    sleep 5
done
echo "K3s nodes are ready."

echo "--- Step 2: Installing Helm ---"
echo "Downloading and installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo "Helm installed successfully."

echo "--- Step 3: Setting up Rancher Helm Chart Repository ---"
echo "Adding Rancher stable Helm repository..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

echo "--- Step 4: Installing Cert-Manager ---"
echo "Applying Cert-Manager manifest..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
echo "Waiting for Cert-Manager deployment to be ready..."
kubectl_n_cert_manager_rollout_status_deploy_cert_manager="kubectl -n cert-manager rollout status deploy/cert-manager"
until $kubectl_n_cert_manager_rollout_status_deploy_cert_manager; do
    echo "Waiting for cert-manager to be ready..."
    sleep 10
done
echo "Cert-Manager is ready."

echo "--- Step 5: Installing Rancher via Helm ---"
echo "Creating 'cattle-system' namespace..."
kubectl create namespace cattle-system || true
echo "'cattle-system' namespace ensured."

read -p "Enter the IP address of your Linux node (e.g., 192.168.1.100): " LINUX_NODE_IP

if [ -z "$LINUX_NODE_IP" ]; then
    echo "Error: Linux node IP address cannot be empty. Exiting."
    exit 1
fi

RANCHER_VERSION="2.12.2"
BOOTSTRAP_PASSWORD="Rancher@1234"

echo "Installing Rancher version $RANCHER_VERSION..."
echo "Using hostname: $LINUX_NODE_IP.sslip.io"
echo "Using bootstrap password: $BOOTSTRAP_PASSWORD"

sleep 5

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname="$LINUX_NODE_IP.sslip.io" \
  --set replicas=1 \
  --set bootstrapPassword="$BOOTSTRAP_PASSWORD" \
  --version "$RANCHER_VERSION"

echo "Rancher installation initiated. It may take a few minutes for all pods to be ready."
echo "You can check the status with: kubectl -n cattle-system get pods"
echo "Once ready, you can access Rancher at: https://$LINUX_NODE_IP.sslip.io"
echo "Initial login password: $BOOTSTRAP_PASSWORD"

echo "Rancher installation script finished."
