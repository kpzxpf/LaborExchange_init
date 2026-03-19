# LaborExchange — Kubernetes Deployment

## Prerequisites

- Kubernetes cluster (Docker Desktop, minikube, or cloud provider)
- `kubectl` configured and pointing to your cluster
- Docker (for building images)

## Step 1 — Build Docker Images

Build and tag each service image. Run from the project root where each service directory is located:

```bash
# API Gateway
docker build -t laborexchange/api-gateway:latest ./LaborExchange_apigateway

# Backend services
docker build -t laborexchange/auth-service:latest ./LaborExchange_authservice
docker build -t laborexchange/user-service:latest ./LaborExchange_userservice
docker build -t laborexchange/vacancy-service:latest ./LaborExchange_vacancyservice
docker build -t laborexchange/resume-service:latest ./LaborExchange_resumeservice
docker build -t laborexchange/application-service:latest ./LaborExchange_applicationservice
docker build -t laborexchange/skill-service:latest ./LaborExchange_skillservice
docker build -t laborexchange/search-service:latest ./LaborExchange_searchservice
docker build -t laborexchange/notification-service:latest ./LaborExchange_notificationservice

# Frontend
docker build -t laborexchange/frontend:latest ./LaborExchange_frontend
```

If using minikube, load images into its Docker daemon first:
```bash
eval $(minikube docker-env)
# then run all docker build commands above
```

## Step 2 — Configure Secrets

Edit `secrets.yaml` and replace the placeholder values before deploying:

- `jwt-secret` — replace with a strong random string (minimum 32 characters)
- `mail-password` — replace with your Gmail App Password

Database credentials can be left as-is for development, or changed for production.

## Step 3 — Run deploy.sh

```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Create the `laborexchange` namespace
2. Apply secrets
3. Deploy all infrastructure (Redis, Kafka, Elasticsearch, PostgreSQL)
4. Wait for infrastructure pods to become ready
5. Deploy all application services and the frontend

## Step 4 — Check Status

```bash
# View all pods
kubectl get pods -n laborexchange

# View all services (find LoadBalancer external IPs)
kubectl get services -n laborexchange

# View deployments
kubectl get deployments -n laborexchange

# View persistent volume claims
kubectl get pvc -n laborexchange
```

## Viewing Logs

```bash
# Logs for a specific service
kubectl logs -n laborexchange deployment/auth-service
kubectl logs -n laborexchange deployment/api-gateway
kubectl logs -n laborexchange deployment/frontend

# Follow logs in real time
kubectl logs -n laborexchange deployment/user-service -f

# Logs for a specific pod (get pod name from kubectl get pods)
kubectl logs -n laborexchange <pod-name>

# Previous container logs (if pod restarted)
kubectl logs -n laborexchange <pod-name> --previous
```

## Accessing the Application

After deployment, get the external IP of the LoadBalancer services:

```bash
kubectl get service frontend -n laborexchange
kubectl get service api-gateway -n laborexchange
```

- Frontend: `http://<FRONTEND_EXTERNAL_IP>:3000`
- API Gateway: `http://<GATEWAY_EXTERNAL_IP>:8080`

On minikube, use `minikube service frontend -n laborexchange --url` to get the URL.

## Teardown

```bash
# Delete everything in the namespace
kubectl delete namespace laborexchange

# Or delete individual resources
kubectl delete -f services/
kubectl delete -f infra/
kubectl delete -f secrets.yaml
kubectl delete -f namespace.yaml
```

## File Structure

```
k8s/
  namespace.yaml          — Namespace definition
  secrets.yaml            — Database credentials and app secrets
  deploy.sh               — Deployment script
  infra/
    redis.yaml            — Redis cache
    kafka.yaml            — Kafka broker (KRaft mode, no ZooKeeper)
    elasticsearch.yaml    — Elasticsearch (single-node, security disabled)
    postgres.yaml         — 5 PostgreSQL instances (user, vacancy, resume, application, skill)
  services/
    api-gateway.yaml      — API Gateway (port 8080, LoadBalancer, HPA)
    auth-service.yaml     — Auth Service (port 8081)
    user-service.yaml     — User Service (port 8082)
    vacancy-service.yaml  — Vacancy Service (port 8083)
    resume-service.yaml   — Resume Service (port 8084)
    application-service.yaml — Application Service (port 8085)
    skill-service.yaml    — Skill Service (port 8086)
    search-service.yaml   — Search Service (port 8087, Elasticsearch)
    notification-service.yaml — Notification Service (port 8088, email)
    frontend.yaml         — Next.js Frontend (port 3000, LoadBalancer)
```
