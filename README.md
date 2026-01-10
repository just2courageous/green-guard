# Green Guard

## 🧩 What this project does
• **FastAPI [Python web framework]** app exposes **`/healthz`**  
• App is containerized with **Docker [containerization]**  
• Deployed to **Kubernetes [container orchestration]** on **EKS [Elastic Kubernetes Service]**  
• **Service [Kubernetes Service]** is **ClusterIP [cluster internal IP]**, so access is done with **kubectl port-forward [Kubernetes command line interface port forward]**  
• Delivery is **GitOps [Git Operations]** with **Argo CD [GitOps continuous delivery]**  
• Build and push is **CI/CD [Continuous Integration and Continuous Delivery]** with **GitHub Actions [CI/CD automation]**  
• AWS access is via **OIDC [OpenID Connect]** using **IAM [Identity and Access Management]** trust

## 🏗️ Architecture
![Green Guard Architecture](docs/diagrams/green-guard-arch.png)

## 🔁 Delivery flow
### 🧱 CI/CD [Continuous Integration and Continuous Delivery]
• **Developer** pushes to **GitHub repo**  
• **GitHub Actions** builds the image  
• Pushes image to **ECR [Elastic Container Registry]** using **IAM [Identity and Access Management] role** via **OIDC [OpenID Connect]**  
• GitHub Actions also **stamps rollout SHA [Secure Hash Algorithm]** into `k8s/deployment.yaml` so Argo CD triggers a rollout

### 🐙 GitOps [Git Operations]
• **Argo CD** watches the repo  
• Argo CD syncs `k8s/` manifests into **EKS [Elastic Kubernetes Service]**  
• **Deployment [Kubernetes Deployment]** runs Pods  
• **Service [Kubernetes Service]** routes traffic to Pods

## 🩺 Health check path (how ClusterIP becomes reachable)
• **Browser** `localhost:8081/healthz`  
• → **kubectl port-forward [Kubernetes command line interface port forward]** `8081 → Service`  
• → **Service (ClusterIP [cluster internal IP])**  
• → **Pods (FastAPI [Python web framework])** `/healthz`

## 🛠️ Run locally
• Create venv [virtual environment] and install dependencies

```bash
python -m venv .venv
# Windows PowerShell [Windows shell]
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
