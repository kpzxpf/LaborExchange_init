#!/bin/bash
set -e

echo "=== Deploying LaborExchange to Kubernetes ==="

# Create namespace
kubectl apply -f namespace.yaml

# Apply secrets (edit secrets.yaml with real values first!)
echo "Applying secrets..."
kubectl apply -f secrets.yaml

# Deploy infrastructure
echo "Deploying infrastructure..."
kubectl apply -f infra/redis.yaml
kubectl apply -f infra/kafka.yaml
kubectl apply -f infra/elasticsearch.yaml
kubectl apply -f infra/postgres.yaml

# Wait for infra to be ready
echo "Waiting for infrastructure..."
kubectl wait --for=condition=ready pod -l app=redis -n laborexchange --timeout=120s
kubectl wait --for=condition=ready pod -l app=kafka -n laborexchange --timeout=180s
kubectl wait --for=condition=ready pod -l app=elasticsearch -n laborexchange --timeout=180s

# Deploy services
echo "Deploying services..."
kubectl apply -f services/

echo "=== Deployment complete! ==="
echo "Check status: kubectl get pods -n laborexchange"
