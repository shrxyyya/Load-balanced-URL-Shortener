#!/bin/bash

# Function to check if minikube tunnel is running
check_tunnel() {
  if ! pgrep -f "minikube tunnel" > /dev/null; then
    echo "Starting minikube tunnel..."
    minikube tunnel > /dev/null 2>&1 &
    TUNNEL_PID=$!
    # Wait for tunnel to start
    sleep 10
    echo "Tunnel started with PID $TUNNEL_PID"
  else
    echo "Minikube tunnel already running"
    TUNNEL_PID=$(pgrep -f "minikube tunnel")
  fi
}

# Start by checking/starting the tunnel
check_tunnel

# Get the service URL
SERVICE_IP=$(kubectl get service urlshortener-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$SERVICE_IP" ]; then
  echo "Error: Could not get service IP. Is the service running?"
  exit 1
fi
SERVICE_PORT=$(kubectl get service urlshortener-service -o jsonpath='{.spec.ports[0].port}')
SERVICE_URL="http://$SERVICE_IP:$SERVICE_PORT"

echo "Service URL: $SERVICE_URL"

# Function to display HPA and pod status
show_status() {
  echo "-------------------------------------"
  echo "Current HPA status:"
  kubectl get hpa urlshortener-hpa
  echo ""
  echo "Current pods:"
  kubectl get pods | grep urlshortener
  echo "-------------------------------------"
}

# Initial status before test
echo "Initial status before stress test:"
show_status

# Function to run concurrent requests in batches
run_stress_test() {
  local concurrent_requests=$1
  local batch_count=$2
  local delay=$3
  
  echo "Starting stress test with $concurrent_requests concurrent requests × $batch_count batches"
  
  for i in $(seq 1 $batch_count); do
    echo "Batch $i/$batch_count - Launching $concurrent_requests concurrent requests..."
    
    # Launch concurrent requests
    for j in $(seq 1 $concurrent_requests); do
      curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
        -d "long_url=https://example.com/stress-test-$i-$j" \
        "$SERVICE_URL/shorten" > /dev/null &
    done
    
    # Wait for all background curl processes to finish
    wait
    
    echo "Batch $i complete"
    show_status
    
    # Delay between batches
    if [ $i -lt $batch_count ]; then
      echo "Waiting $delay seconds before next batch..."
      sleep $delay
    fi
  done
}

# Run moderate load test - 50 concurrent requests × 6 batches
echo "Starting moderate load test..."
run_stress_test 50 6 5

echo "Monitoring HPA and pods for scale down (60 seconds)..."
for i in $(seq 1 6); do
  sleep 10
  echo "Status $i/6 (after $((i*10)) seconds):"
  show_status
done

# Run heavy load test - 100 concurrent requests × 10 batches
echo "Starting heavy load test..."
run_stress_test 100 10 5

echo "Monitoring HPA and pods for scale down (120 seconds)..."
for i in $(seq 1 12); do
  sleep 10
  echo "Status $i/12 (after $((i*10)) seconds):"
  show_status
done

echo "Stress test completed"

# Clean up the tunnel if we started it
if [ ! -z "$TUNNEL_PID" ]; then
  echo "Stopping minikube tunnel (PID: $TUNNEL_PID)..."
  kill $TUNNEL_PID
fi