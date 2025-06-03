# Load-Balanced URL Shortener

A scalable URL shortening service built with Flask and MySQL, deployed on Kubernetes with load balancing capabilities.

## Features

- URL shortening and redirection
- Load balancing across multiple replicas
- Persistent MySQL storage
- Horizontal Pod Autoscaling (HPA)
- Stress testing capabilities
- Monitoring and metrics

## Prerequisites

1. Install the following tools:
   - Docker Desktop with WSL2 backend
   - Minikube
   - kubectl
   - Python 3.x (for local development)

2. Verify installations
```bash
docker --version
minikube version
kubectl version
```

### Linux/WSL Installation
```bash
# Install Docker
sudo apt-get update
sudo apt-get install docker.io

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Project Setup

1. Clone the repository:
```bash
git clone https://github.com/shrxyyya/Load-balanced-URL-Shortener.git
cd Load-balanced-URL-Shortener
```

2. Start Minikube:
```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify Minikube is running
minikube status
```

3. Build and deploy the application:
```bash
# Point shell to minikube's docker-daemon
eval $(minikube docker-env)

# Build the Docker image
docker build -t urlshortener:latest .

# Apply Kubernetes configurations
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-configmap.yaml
kubectl apply -f k8s/urlshortener-config.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/urlshortener-deployment.yaml

# Verify all pods are running
kubectl get pods -w
```

4. Access the application:
```bash
# Terminal 1: Start minikube tunnel (keep this terminal open)
minikube tunnel

# Terminal 2: Forward MySQL port (keep this terminal open) - because my server was created on port 3307
kubectl port-forward service/mysql-service 3307:3306

# Terminal 3: Get the service URL
kubectl get service urlshortener-service
```

The application will be available at http://<EXTERNAL-IP> shown in the service output.

## Testing

### Basic API Testing

1. Make the test script executable:
```bash
chmod +x test_api.sh
dos2unix test_api.sh
```

2. Run the test script:
```bash
./test_api.sh
```

This will:
- Create 10 shortened URLs
- Test redirections
- Show load balancing across pods

### Stress Testing

1. Basic Stress Test:
```bash
# Terminal 4: Monitor CPU usage
watch -n 2 "kubectl top pods | grep urlshortener"

# -- OR --
# Terminal 4: Monitor HPA - Check current replica set information
kubectl get hpa urlshortener-hpa

# Terminal 3: Run basic stress test
./basic_stress_test.sh
```

2. Advanced Stress Test:
```bash
# Terminal 3: Run advanced stress test
./adv_stress_test.sh
```

The stress tests will:
- Simulate multiple concurrent users
- Test system performance under load
- Monitor response times and success rates
- Verify load balancing effectiveness

## Monitoring

1. View application logs:
```bash
# View URL shortener logs
kubectl logs -l app=urlshortener

# View MySQL logs
kubectl logs -l app=mysql
```

## Troubleshooting

1. If pods are not starting:
```bash
kubectl describe pods
```

2. If the service is not accessible:
```bash
# Check service status
kubectl get services

# Check service endpoints
kubectl get endpoints urlshortener-service
```

3. To restart deployments:
```bash
kubectl rollout restart deployment urlshortener-deployment
kubectl rollout restart deployment mysql-deployment
```

## Cleanup

To stop and clean up the project:

```bash
# Delete all resources
kubectl delete -f k8s/

# Stop minikube
minikube stop

# Optional: Delete minikube cluster
minikube delete
```

## Environment Variables

The application uses the following environment variables (configured in ConfigMaps and Secrets):

- MYSQL_HOST: MySQL service hostname
- MYSQL_PORT: MySQL port (default: 3306)
- MYSQL_USER: MySQL username
- MYSQL_PASSWORD: MySQL password (in secret)
- MYSQL_DATABASE: Database name
- FLASK_ENV: Flask environment

## Architecture

The application consists of:
- MySQL Deployment (single pod for data consistency)
- URL Shortener Deployment (3 replicas for high availability)
- Persistent Volume for MySQL data
- Load Balancer Service for external access
- Horizontal Pod Autoscaler for dynamic scaling 
