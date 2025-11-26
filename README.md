#### To install Rancher on Ubuntu, Below is a step-by-step guide using K3s (lightweight Kubernetes) on Ubuntu.

Step 1: Install K3s (Lightweight Kubernetes)
 ```bash
curl -sfL https://get.k3s.io | sh - 
```
If you want to install specific kubernetes version 
 ```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.30.1+k3s1" sh -
```

Wait until it's ready:

 ```bash
sudo kubectl get nodes
```

Export kubeconfig for your user:

```bash
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

Step 2: Install Helm
 ```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```

Step 3: Set up Rancher Helm Chart Repo
 ```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
```

Step 4: Install Cert-Manager
 ```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
```

Wait for it to become ready:
 ```bash
kubectl -n cert-manager rollout status deploy/cert-manager
```

Step 5: Install Rancher via Helm
First create namespace
 ```bash
kubectl create namespace cattle-system
```
To install a specific Rancher version, use the **--version** flag (e.g., --version 2.12.2). Otherwise, the latest Rancher is installed by default

```bash
helm install rancher rancher-stable/rancher  --namespace cattle-system \
--set hostname=<IP_OF_LINUX_NODE>.sslip.io> \
--set replicas=1 \
--set bootstrapPassword=Rancher@1234 \
--version 2.11.2
```

## Uninstalling K3s

#### To uninstall K3s from a server node, run:
```bash
/usr/local/bin/k3s-uninstall.sh
```
#### To uninstall K3s from an agent node, run:
```bash
/usr/local/bin/k3s-agent-uninstall.sh
```
