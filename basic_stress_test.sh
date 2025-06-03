#!/bin/bash

# Get service URL
SERVICE_IP=$(kubectl get service urlshortener-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SERVICE_PORT=$(kubectl get service urlshortener-service -o jsonpath='{.spec.ports[0].port}')
SERVICE_URL="http://$SERVICE_IP:$SERVICE_PORT"

echo "Starting stress test on $SERVICE_URL"

# Run 50 concurrent requests in a loop
for i in {1..10}; do
  echo "Starting batch $i of requests..."
  
  # Launch 50 concurrent requests
  for j in {1..50}; do
    curl -s -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "long_url=https://example.com/stress-test-$i-$j" \
      "$SERVICE_URL/shorten" > /dev/null &
  done
  
  # Wait for current batch to complete
  wait
  
  # Check HPA status
  echo "HPA status after batch $i:"
  kubectl get hpa urlshortener-hpa
  
  # Brief pause between batches
  sleep 2
done

echo "Stress test complete. Monitoring HPA for 2 minutes:"

# Monitor HPA for scale down
for i in {1..12}; do
  echo "HPA status at $((i*10)) seconds after test:"
  kubectl get hpa urlshortener-hpa
  kubectl get pods | grep urlshortener
  sleep 10
done