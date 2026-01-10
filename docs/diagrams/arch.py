from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.iac import Terraform
from diagrams.onprem.client import User
from diagrams.aws.compute import EKS, ECR
from diagrams.aws.security import IAMRole
from diagrams.aws.network import VPC
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.network import Service

graph_attr = {
    "pad": "1.0",
    "splines": "ortho",
    "nodesep": "1.2",
    "ranksep": "1.5",
    "fontsize": "12",
    "dpi": "300",
}

with Diagram(
    "Green-Guard: Terraform + GitHub Actions + Argo CD on EKS",
    show=False,
    filename="docs/diagrams/green-guard-arch",
    outformat="png",
    direction="LR",
    graph_attr=graph_attr,
):
    # --- External Users/Repo ---
    dev = User("Developer\n(You)")
    repo = Github("GitHub repo")
    
    with Cluster("CI/CD Pipeline"):
        actions = GithubActions("GitHub Actions\nCI/CD")
        role = IAMRole("IAM role\nOIDC")

    argocd = Argocd("Argo CD\nGitOps")

    # --- AWS Infrastructure ---
    with Cluster("AWS"):
        terraform = Terraform("Terraform\nIaC")
        ecr = ECR("ECR\nRegistry")
        vpc = VPC("VPC")
        eks = EKS("EKS\nCluster")

        with Cluster("Kubernetes"):
            deploy = Deployment("Deployment")
            svc = Service("Service\nClusterIP\n8080")
            pods = Pod("Pods\nFastAPI /healthz")

    # --- Local Access Chain ---
    browser = User("Browser\nlocalhost:8081/healthz")
    portfw = User("kubectl port-forward\n8081 → svc")

    # -------------------- FLOWS --------------------
    # 1) Fix: Actions -> Repo with "Stamp Rollout SHA"
    dev >> repo >> actions
    actions >> Edge(label="commit k8s manifests\n+ stamp rollout SHA", color="darkorange", style="bold") >> repo
    
    # 2) CI Image Flow
    actions >> Edge(label="assume role (OIDC)") >> role
    role >> Edge(label="push image") >> ecr
    ecr >> Edge(label="image pull") >> pods

    # 3) Infrastructure & GitOps
    terraform >> [vpc, eks]
    repo >> Edge(label="watched repo") >> argocd
    argocd >> Edge(label="sync k8s/") >> eks
    eks >> Edge(label="apply manifests") >> deploy >> pods

    # 4) Fix: Clear Port-Forward Chain & Service->Pod link
    # Browser -> PortForward -> Service -> Pods
    browser >> portfw >> svc
    svc >> Edge(label="routes traffic", style="dashed") >> pods