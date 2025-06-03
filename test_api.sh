#!/bin/bash

# Start minikube tunnel in the background
echo "Starting minikube tunnel..."
minikube tunnel > /dev/null 2>&1 &
TUNNEL_PID=$!

# Wait for tunnel to be ready
sleep 5

# Get the service URL using kubectl
SERVICE_IP=$(kubectl get service urlshortener-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SERVICE_PORT=$(kubectl get service urlshortener-service -o jsonpath='{.spec.ports[0].port}')
SERVICE_URL="http://$SERVICE_IP:$SERVICE_PORT"

echo "Service URL: $SERVICE_URL"

# Function to send requests
send_requests() {
    for i in {1..30}; do
        echo "Request $i:"
        # Send POST request to create short URL with proper form data
        response=$(curl -s -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -H "Accept: application/json" \
            --data-urlencode "long_url=https://example.com/$i" \
            "$SERVICE_URL/shorten")
        
        # Extract and display the shortened URL
        short_url=$(echo "$response" | grep -o 'http://[^"]*' | head -1)
        echo "Original URL: https://example.com/$i"
        echo "Shortened URL: $short_url"
        echo -e "-------------------"
        
        # Test the redirection (optional)
        if [ ! -z "$short_url" ]; then
            echo "Testing redirection:"
            redirect_response=$(curl -s -I "$short_url" | grep -i "location" || echo "No redirect found")
            echo "$redirect_response"
            echo -e "-------------------\n"
        fi
        
        sleep 1
    done
}

# Test multiple instances
echo "Testing multiple instances..."
send_requests

# Get pods to see which instance handled which request
echo -e "\nPod logs:"
for pod in $(kubectl get pods -l app=urlshortener -o jsonpath='{.items[*].metadata.name}'); do
    echo -e "\nLogs from pod $pod:"
    kubectl logs $pod --tail=20
done

# Display load balancing statistics
echo -e "\nLoad Balancing Statistics:"
for pod in $(kubectl get pods -l app=urlshortener -o jsonpath='{.items[*].metadata.name}'); do
    requests=$(kubectl logs $pod | grep "POST /shorten" | wc -l)
    echo "Pod $pod handled $requests requests"
done

# Clean up
echo "Cleaning up..."
kill $TUNNEL_PID 