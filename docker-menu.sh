#!/bin/bash

# ==============================================================================
# CONFIGURATION ENVIRONMENT VARIABLES
# ==============================================================================
# Uses local environment variables or falls back to configured default values
IMAGE_NAME="${DOCKER_IMAGE_NAME:-mi-portafolio}"
CONTAINER_NAME="${DOCKER_CONTAINER_NAME:-mi-portafolio-web}"
DOCKER_HUB_USER="${DOCKER_REGISTRY_USER:-juangcarvajal}"
PORT="${DOCKER_SANDBOX_PORT:-8080}"

# --- ANSI COLOR CODES ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==============================================================================
# TOOL VERIFICATION & INITIALIZATION BANNER
# ==============================================================================
if ! command -v docker &> /dev/null || ! command -v figlet &> /dev/null || ! command -v lolcat &> /dev/null; then
    echo -e "${RED}[ERR] Missing core dependencies. Please run: 'sudo pacman -S docker figlet lolcat'${NC}"
    exit 1
fi

clear
# Render dynamic framework banner using figlet and lolcat
figlet -f slant "DK-ORCHESTRATOR" | lolcat

echo -e "${CYAN}====================================================================${NC}"
echo -e "  ${BOLD}DOCKER SMART LIFE-CYCLE UTILITY${NC}   |  Target Image: ${YELLOW}$IMAGE_NAME${NC}"
echo -e "  Sandbox Port: ${GREEN}$PORT -> 80 (Nginx)${NC}      |  Registry Vault: ${MAGENTA}$DOCKER_HUB_USER${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo ""

# Simulated rapid systems initialization logs
echo -e "[${GREEN}INF${NC}] Interfacing with local Docker virtualization engine socket..."
sleep 0.04
echo -e "[${GREEN}INF${NC}] Auditing standalone BuildKit daemon components..."
sleep 0.05

if docker info &>/dev/null; then
    echo -e "[${GREEN} OK ${NC}] Docker socket layer is active and accepting connections."
else
    echo -e "[${RED}WARN${NC}] Cannot reach Docker daemon. Make sure 'sudo systemctl start docker' is active."
fi
sleep 0.06

echo ""
echo -e " * Environment ready. Injecting main routing vectors..."
echo -e "${CYAN}--------------------------------------------------------------------${NC}"
sleep 0.15

# ==============================================================================
# CORE WORKFLOW LIFECYCLE PERSISTENT LOOP
# ==============================================================================
while true; do
    echo -e "  ${CYAN}1)${NC} Iniciar contenedor local"
    echo -e "  ${CYAN}2)${NC} Actualizar contenedor (Recompilar local + Push opcional)"
    echo -e "  ${CYAN}3)${NC} Apagar contenedor (Liberar puerto)"
    echo -e "  ${CYAN}4)${NC} Ver logs en tiempo real"
    echo -e "  ${CYAN}5)${NC} Limpieza profunda de Docker"
    echo -e "  ${CYAN}6)${NC} Salir"
    echo -e "${CYAN}--------------------------------------------------------------------${NC}"
    read -p "[+] Selecciona una opción [1-6]: " opcion

    case $opcion in
        1)
            echo -e "\n[+] Verificando la integridad del puerto $PORT..."
            
            EXISTING_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
            if [ ! -z "$EXISTING_DOCKER_ID" ]; then
                echo -e "${YELLOW}[!] Se detectó un contenedor fantasma usando el puerto $PORT. Eliminándolo...${NC}"
                sudo docker stop $EXISTING_DOCKER_ID &>/dev/null
                sudo docker rm $EXISTING_DOCKER_ID &>/dev/null
            fi

            if sudo lsof -i :$PORT -t &>/dev/null; then
                echo -e "\n${RED}[ERR] El puerto $PORT sigue ocupado por un proceso de tu Arch Linux (quizás Vite local).${NC}"
                echo -e "[-] Por favor, cierra ese proceso o ejecuta: 'sudo kill -9 \$(sudo lsof -t -i:$PORT)'"
                echo -e "${CYAN}--------------------------------------------------------------------${NC}"
                continue
            fi

            echo -e "[+] Puerto libre. Iniciando contenedor en http://localhost:$PORT..."
            sudo docker run -d --rm --name $CONTAINER_NAME -p $PORT:80 $IMAGE_NAME
            
            echo -e "\n${GREEN}[🎉] Estado actual del microservicio:${NC}"
            sudo docker ps --filter name=$CONTAINER_NAME
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;

        2)
            echo -e "\n[+] Limpiando entorno de ejecución antes de compilar..."
            sudo docker stop $CONTAINER_NAME &>/dev/null
            
            echo -e "[+] Recompilando la imagen usando BuildKit moderno..."
            sudo docker buildx build --network=host --no-cache -t $IMAGE_NAME .
            
            echo -e "\n[+] Reiniciando el contenedor de pruebas en el sandbox local..."
            sudo docker run -d --rm --name $CONTAINER_NAME -p $PORT:80 $IMAGE_NAME
            echo -e "${GREEN}[🎉] ¡Compilación local completada con éxito!${NC}"
            
            # --- LOCAL CODE AUDIT BOX ---
            echo -e "\n${CYAN}====================================================================${NC}"
            echo -e "🔍  ${BOLD}REVISIÓN LOCAL ANTES DEL DESPLIEGUE:${NC}"
            echo -e "Abre este enlace en tu navegador para verificar los cambios:\n"
            echo -e "   👉  \033[1;34mhttp://localhost:$PORT\033[0m  👈"
            echo -e "${CYAN}====================================================================${NC}"
            
            read -p "[?] ¿Deseas subir esta versión a internet (Docker Hub)? [s/N]: " subir_nube
            if [[ "$subir_nube" =~ ^[Ss]$ ]]; then
                echo -e "\n[+] Generando tag para la cuenta de destino: $DOCKER_HUB_USER..."
                sudo docker tag $IMAGE_NAME:latest $DOCKER_HUB_USER/$IMAGE_NAME:latest
                
                echo -e "[+] Subiendo capas modificadas upstream a Docker Hub..."
                sudo docker push $DOCKER_HUB_USER/$IMAGE_NAME:latest
                
                echo -e "\n${GREEN}[🎉] ¡Imagen en la nube actualizada! Ya puedes ir a Render y darle a 'Manual Deploy'.${NC}"
            else
                echo -e "${YELLOW}[-] Subida cancelada. Los cambios solo se aplicaron a la caché local.${NC}"
            fi
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;

        3)
            echo -e "\n[-] Buscando procesos activos en el puerto $PORT para apagar..."
            sudo docker stop $CONTAINER_NAME &>/dev/null
            
            ANY_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
            if [ ! -z "$ANY_DOCKER_ID" ]; then
                sudo docker stop $ANY_DOCKER_ID &>/dev/null
            fi
            
            echo -e "${GREEN}[+] Puerto $PORT completamente liberado y limpio.${NC}"
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;

        4)
            if ! sudo docker ps | grep -q $CONTAINER_NAME; then
                ANY_DOCKER_ID=$(sudo docker ps -q --filter "publish=$PORT")
                if [ -z "$ANY_DOCKER_ID" ]; then
                    echo -e "${RED}[!] El contenedor no está corriendo. Inícialo primero (Opción 1).${NC}"
                    echo -e "${CYAN}--------------------------------------------------------------------${NC}"
                    continue
                fi
                CONTAINER_NAME=$ANY_DOCKER_ID
            fi
            echo -e "\n[+] Mostrando transmisión de logs en vivo (Presiona Ctrl+C para salir):\n"
            sudo docker logs -f $CONTAINER_NAME
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;

        5)
            echo -e "\n${RED}[!] Ejecutando limpieza profunda del ecosistema Docker...${NC}"
            sudo docker container prune -f
            sudo docker image prune -f
            echo -e "${GREEN}[+] Caché colgante y contenedores huérfanos eliminados.${NC}"
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;

        6)
            echo -e "\n${GREEN}[-] Cerrando orquestador de Docker. ¡Hasta luego!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}[!] OPCIÓN INVALIDA${NC}"
            echo -e "${CYAN}--------------------------------------------------------------------${NC}"
            ;;
    esac
done
