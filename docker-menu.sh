#!/bin/bash

# ==============================================================================
# CONFIGURATION SECTION
# Change these variables to adapt the script to your specific project
# ==============================================================================
IMAGE_NAME="my-app"                  # Name of your local Docker image
CONTAINER_NAME="my-app-web-service"  # Name for the running container
DOCKER_HUB_USER="your_dockerhub_username" # Your Docker Hub username (e.g., juangcarvajal)
PORT=8080                            # Local port to map the application
TARGET_DOCKER_PORT=80               # Port exposed inside the container (Nginx default)

# ==============================================================================
# CORE SYSTEM (Do not modify below this line unless needed)
# ==============================================================================

clear
echo "========================================="
echo "   SMART DOCKER LIFECYCLE MANAGEMENT     "
echo "========================================="
echo "1) Start local container"
echo "2) Update container (Rebuild local + Optional Registry Push)"
echo "3) Stop container (Free up port)"
echo "4) View real-time container logs"
echo "5) Deep clean Docker environment"
echo "6) Exit"
echo "========================================="
read -p "Select an option [1-6]: " opcion

case $opcion in
    1)
        echo -e "\n[+] Auditing local port $PORT..."
        
        # 1. Remove ghost containers bound to the same port
        EXISTING_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
        if [ ! -z "$EXISTING_DOCKER_ID" ]; then
            echo "[!] Detected a ghost container using port $PORT. Removing..."
            sudo docker stop $EXISTING_DOCKER_ID &>/dev/null
            sudo docker rm $EXISTING_DOCKER_ID &>/dev/null
        fi

        # 2. Check if a native host process is occupying the port
        if sudo lsof -i :$PORT -t &>/dev/null; then
            echo -e "\n[ERR] Port $PORT is currently occupied by a host OS process (e.g., native Vite dev server)."
            echo "[-] Please terminate that process or execute: 'sudo kill -9 \$(sudo lsof -t -i:$PORT)'"
            exit 1
        fi

        echo "[+] Port is free. Starting container at http://localhost:$PORT..."
        sudo docker run -d --rm --name $CONTAINER_NAME -p $PORT:$TARGET_DOCKER_PORT $IMAGE_NAME
        
        echo -e "\n[+] Current Container Status:"
        sudo docker ps --filter name=$CONTAINER_NAME
        ;;

    2)
        echo -e "\n[+] Cleaning runtime environment before compiling..."
        sudo docker stop $CONTAINER_NAME &>/dev/null
        
        echo "[+] Rebuilding container image utilizing modern BuildKit..."
        sudo docker buildx build --network=host --no-cache -t $IMAGE_NAME .
        
        echo -e "\n[+] Launching local sandbox test container..."
        sudo docker run -d --rm --name $CONTAINER_NAME -p $PORT:$TARGET_DOCKER_PORT $IMAGE_NAME
        echo "[+] Local compilation completed successfully!"
        
        # --- PRE-DEPLOYMENT AUDIT SECTION ---
        echo -e "\n========================================="
        echo "🔍 LOCAL PRE-DEPLOYMENT AUDIT:"
        echo -e "Open the link below to verify changes inside the container environment:\n"
        echo -e "   👉  \e[1;34mhttp://localhost:$PORTe[0m  👈"
        echo "========================================="
        
        read -p "Do you want to push this verified build to remote Registry (Docker Hub)? [s/N]: " subir_nube
        if [[ "$subir_nube" =~ ^[Ss]$ ]]; then
            echo -e "\n[+] Tagging binary build for target user: $DOCKER_HUB_USER..."
            sudo docker tag $IMAGE_NAME:latest $DOCKER_HUB_USER/$IMAGE_NAME:latest
            
            echo "[+] Uploading modified layers upstream to Docker Hub..."
            sudo docker push $DOCKER_HUB_USER/$IMAGE_NAME:latest
            
            echo -e "\n[🎉] Remote registry updated! You can now trigger 'Manual Deploy' on your Cloud Provider (Render)."
        else
            echo "[-] Upload aborted. Changes were only applied to the local image cache."
        fi
        echo "========================================="
        ;;

    3)
        echo -e "\n[-] Stopping active processes on port $PORT..."
        sudo docker stop $CONTAINER_NAME &>/dev/null
        
        ANY_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
        if [ ! -z "$ANY_DOCKER_ID" ]; then
            sudo docker stop $ANY_DOCKER_ID &>/dev/null
        fi
        
        echo "[+] Port $PORT has been fully cleared and released."
        ;;

    4)
        if ! sudo docker ps | grep -q $CONTAINER_NAME; then
            ANY_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
            if [ -z "$ANY_DOCKER_ID" ]; then
                echo "[!] Target container is not active. Please start it first (Option 1)."
                exit 1
            fi
            CONTAINER_NAME=$ANY_DOCKER_ID
        fi
        echo -e "\n[+] Streaming dynamic log outputs (Press Ctrl+C to disconnect):\n"
        sudo docker logs -f $CONTAINER_NAME
        ;;

    5)
        echo -e "\n[!] Initializing deep container ecosystem cleanup..."
        sudo docker container prune -f
        sudo docker image prune -f
        echo "[+] Workspace cleared successfully."
        ;;

    6)
        echo -e "\nGoodbye!"
        exit 0
        ;;
    *)
        echo -e "\n[INVALID OPTION SELECTED]"
        ;;
esac
