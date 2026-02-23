#!/bin/bash

# TempConv Automated Google Cloud Deployment Script
# This script deploys the entire TempConv application to Google Kubernetes Engine

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  TempConv GCloud Deployment Script${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: No GCloud project configured${NC}"
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}✓ Using project: $PROJECT_ID${NC}"
echo ""

# Step 1: Enable required APIs
echo -e "${BLUE}Step 1: Enabling required APIs...${NC}"
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
echo -e "${GREEN}✓ APIs enabled${NC}"
echo ""

# Step 2: Build Docker images
echo -e "${BLUE}Step 2: Building Docker images...${NC}"
echo "Building backend..."
gcloud builds submit --config=cloudbuild-backend.yaml .
echo -e "${GREEN}✓ Backend image built${NC}"

echo "Building proxy..."
gcloud builds submit --config=cloudbuild-proxy.yaml .
echo -e "${GREEN}✓ Proxy image built${NC}"

echo "Building frontend..."
gcloud builds submit --config=cloudbuild-frontend.yaml .
echo -e "${GREEN}✓ Frontend image built${NC}"
echo ""

# Step 3: Create GKE cluster (if it doesn't exist)
echo -e "${BLUE}Step 3: Setting up GKE cluster...${NC}"
if gcloud container clusters describe tempconv-cluster --zone=us-central1-a &>/dev/null; then
    echo -e "${GREEN}✓ Cluster 'tempconv-cluster' already exists${NC}"
else
    echo "Creating GKE cluster (this may take 3-5 minutes)..."
    gcloud container clusters create tempconv-cluster \
        --zone=us-central1-a \
        --machine-type=e2-medium \
        --num-nodes=2 \
        --enable-autoscaling \
        --min-nodes=2 \
        --max-nodes=4
    echo -e "${GREEN}✓ Cluster created${NC}"
fi
echo ""

# Step 4: Get cluster credentials
echo -e "${BLUE}Step 4: Configuring kubectl...${NC}"
gcloud container clusters get-credentials tempconv-cluster --zone=us-central1-a
echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

# Step 5: Deploy to Kubernetes
echo -e "${BLUE}Step 5: Deploying to Kubernetes...${NC}"
sed "s/PROJECT_ID/$PROJECT_ID/g" k8s-deployment.yaml > k8s-deployment-final.yaml
kubectl apply -f k8s-deployment-final.yaml
echo -e "${GREEN}✓ Deployed to Kubernetes${NC}"
echo ""

# Step 6: Wait for deployments
echo -e "${BLUE}Step 6: Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/tempconv-backend
kubectl wait --for=condition=available --timeout=300s deployment/tempconv-proxy
kubectl wait --for=condition=available --timeout=300s deployment/tempconv-frontend
echo -e "${GREEN}✓ All deployments ready${NC}"
echo ""

# Step 7: Get external IP
echo -e "${BLUE}Step 7: Getting external IP addresses...${NC}"
echo "Waiting for LoadBalancer IPs (this may take 1-2 minutes)..."
sleep 30

FRONTEND_IP=$(kubectl get svc tempconv-frontend-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
PROXY_IP=$(kubectl get svc tempconv-proxy-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

# Wait for IPs if still pending
COUNTER=0
while [ "$FRONTEND_IP" == "pending" ] || [ "$PROXY_IP" == "pending" ]; do
    if [ $COUNTER -gt 12 ]; then
        echo -e "${RED}Timeout waiting for external IPs${NC}"
        echo "Check status with: kubectl get svc"
        exit 1
    fi
    sleep 10
    FRONTEND_IP=$(kubectl get svc tempconv-frontend-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    PROXY_IP=$(kubectl get svc tempconv-proxy-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    COUNTER=$((COUNTER + 1))
done

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✓ DEPLOYMENT SUCCESSFUL!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Your TempConv application is now live at:${NC}"
echo -e "  Frontend:  ${GREEN}http://$FRONTEND_IP${NC}"
echo -e "  Proxy:     ${GREEN}http://$PROXY_IP:8081${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  View pods:        kubectl get pods"
echo "  View services:    kubectl get svc"
echo "  View logs:        kubectl logs -l app=tempconv-backend"
echo "  Delete all:       kubectl delete -f k8s-deployment-final.yaml"
echo "  Delete cluster:   gcloud container clusters delete tempconv-cluster --zone=us-central1-a"
echo ""
