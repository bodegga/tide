#!/bin/bash
# Manage Tide Gateway VMs - Identify, configure, and control

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

show_header() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌊 Tide Gateway VM Manager"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

list_gateways() {
    echo -e "${CYAN}Tide Gateway VMs:${NC}"
    echo ""
    
    prlctl list -a | grep -E "UUID|Tide.*Gateway" | while IFS= read -r line; do
        if echo "$line" | grep -q "UUID"; then
            echo "$line"
        else
            VM_NAME=$(echo "$line" | awk '{print $NF}')
            STATUS=$(echo "$line" | awk '{print $2}')
            
            case "$STATUS" in
                running)
                    STATUS_COLOR="${GREEN}🟢 $STATUS${NC}"
                    ;;
                stopped)
                    STATUS_COLOR="${RED}🔴 $STATUS${NC}"
                    ;;
                suspended)
                    STATUS_COLOR="${YELLOW}🟡 $STATUS${NC}"
                    ;;
                *)
                    STATUS_COLOR="$STATUS"
                    ;;
            esac
            
            echo -e "  $STATUS_COLOR - $VM_NAME"
        fi
    done
    echo ""
}

get_gateway_info() {
    VM_NAME="$1"
    
    echo -e "${CYAN}Getting info for: $VM_NAME${NC}"
    echo ""
    
    STATUS=$(prlctl list -a | grep "$VM_NAME" | awk '{print $2}')
    
    if [ "$STATUS" != "running" ]; then
        echo -e "${YELLOW}VM is not running (status: $STATUS)${NC}"
        echo ""
        echo "Start it with:"
        echo "  prlctl start \"$VM_NAME\""
        return 1
    fi
    
    # Get IP address (may take a moment)
    echo "Waiting for IP address..."
    IP_ADDR=""
    for i in {1..10}; do
        IP_ADDR=$(prlctl list -i "$VM_NAME" | grep "net0" -A 5 | grep "IP address" | awk '{print $3}' | head -1)
        if [ -n "$IP_ADDR" ]; then
            break
        fi
        sleep 1
    done
    
    if [ -n "$IP_ADDR" ]; then
        echo -e "${GREEN}IP Address: $IP_ADDR${NC}"
        echo ""
        
        # Try to get Tide status via SSH (if accessible)
        echo "Attempting to check Tide status..."
        ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@"$IP_ADDR" 'cat /etc/tide/mode 2>/dev/null' | while read -r MODE; do
            echo -e "${GREEN}Mode: $MODE${NC}"
        done 2>/dev/null || echo -e "${YELLOW}Could not connect via SSH${NC}"
        
        ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@"$IP_ADDR" 'cat /etc/tide/security 2>/dev/null' | while read -r SEC; do
            echo -e "${GREEN}Security: $SEC${NC}"
        done 2>/dev/null
        
    else
        echo -e "${YELLOW}No IP address found${NC}"
    fi
    
    echo ""
}

start_gateway() {
    VM_NAME="$1"
    
    echo -e "${CYAN}Starting: $VM_NAME${NC}"
    prlctl start "$VM_NAME"
    
    echo ""
    echo "Waiting for boot..."
    sleep 5
    
    get_gateway_info "$VM_NAME"
}

stop_gateway() {
    VM_NAME="$1"
    
    echo -e "${YELLOW}Stopping: $VM_NAME${NC}"
    prlctl stop "$VM_NAME"
    echo -e "${GREEN}✓ Stopped${NC}"
    echo ""
}

ssh_gateway() {
    VM_NAME="$1"
    
    STATUS=$(prlctl list -a | grep "$VM_NAME" | awk '{print $2}')
    
    if [ "$STATUS" != "running" ]; then
        echo -e "${RED}VM is not running${NC}"
        return 1
    fi
    
    # Get IP
    IP_ADDR=$(prlctl list -i "$VM_NAME" | grep "net0" -A 5 | grep "IP address" | awk '{print $3}' | head -1)
    
    if [ -z "$IP_ADDR" ]; then
        echo -e "${RED}No IP address found${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Connecting to $VM_NAME ($IP_ADDR)...${NC}"
    echo ""
    ssh -o StrictHostKeyChecking=no root@"$IP_ADDR"
}

configure_gateway() {
    VM_NAME="$1"
    MODE="$2"
    SECURITY="$3"
    
    STATUS=$(prlctl list -a | grep "$VM_NAME" | awk '{print $2}')
    
    if [ "$STATUS" != "running" ]; then
        echo -e "${RED}VM is not running${NC}"
        return 1
    fi
    
    IP_ADDR=$(prlctl list -i "$VM_NAME" | grep "net0" -A 5 | grep "IP address" | awk '{print $3}' | head -1)
    
    if [ -z "$IP_ADDR" ]; then
        echo -e "${RED}No IP address found${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Configuring $VM_NAME:${NC}"
    echo "  Mode: $MODE"
    echo "  Security: $SECURITY"
    echo ""
    
    ssh -o StrictHostKeyChecking=no root@"$IP_ADDR" "tide mode $MODE" || {
        echo -e "${RED}Failed to set mode${NC}"
        return 1
    }
    
    ssh -o StrictHostKeyChecking=no root@"$IP_ADDR" "tide security $SECURITY" || {
        echo -e "${RED}Failed to set security${NC}"
        return 1
    }
    
    echo -e "${GREEN}✓ Configuration updated${NC}"
    echo ""
}

label_gateway() {
    VM_NAME="$1"
    NEW_NAME="$2"
    
    echo -e "${CYAN}Renaming VM:${NC}"
    echo "  From: $VM_NAME"
    echo "  To:   $NEW_NAME"
    echo ""
    
    prlctl set "$VM_NAME" --name "$NEW_NAME"
    
    echo -e "${GREEN}✓ Renamed to: $NEW_NAME${NC}"
    echo ""
}

interactive_menu() {
    show_header
    list_gateways
    
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo ""
    echo "  1) Start a gateway"
    echo "  2) Stop a gateway"
    echo "  3) Get gateway info"
    echo "  4) SSH into gateway"
    echo "  5) Configure gateway (mode + security)"
    echo "  6) Rename/label gateway"
    echo "  7) Start all gateways"
    echo "  8) Stop all gateways"
    echo "  9) Exit"
    echo ""
    echo -n "Choose option [1-9]: "
    read -r CHOICE
    
    echo ""
    
    case "$CHOICE" in
        1)
            echo -n "VM name: "
            read -r VM_NAME
            start_gateway "$VM_NAME"
            ;;
        2)
            echo -n "VM name: "
            read -r VM_NAME
            stop_gateway "$VM_NAME"
            ;;
        3)
            echo -n "VM name: "
            read -r VM_NAME
            get_gateway_info "$VM_NAME"
            ;;
        4)
            echo -n "VM name: "
            read -r VM_NAME
            ssh_gateway "$VM_NAME"
            ;;
        5)
            echo -n "VM name: "
            read -r VM_NAME
            echo -n "Mode (proxy/router/killa-whale/takeover): "
            read -r MODE
            echo -n "Security (standard/hardened/paranoid/bridges): "
            read -r SECURITY
            configure_gateway "$VM_NAME" "$MODE" "$SECURITY"
            ;;
        6)
            echo -n "Current VM name: "
            read -r VM_NAME
            echo -n "New VM name: "
            read -r NEW_NAME
            label_gateway "$VM_NAME" "$NEW_NAME"
            ;;
        7)
            prlctl list -a | grep "Tide.*Gateway" | awk '{print $NF}' | while read -r VM; do
                echo "Starting $VM..."
                prlctl start "$VM" 2>/dev/null || true
            done
            echo -e "${GREEN}✓ All gateways started${NC}"
            ;;
        8)
            prlctl list -a | grep "Tide.*Gateway" | awk '{print $NF}' | while read -r VM; do
                echo "Stopping $VM..."
                prlctl stop "$VM" 2>/dev/null || true
            done
            echo -e "${GREEN}✓ All gateways stopped${NC}"
            ;;
        9)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Quick commands
CMD="${1:-interactive}"

case "$CMD" in
    list)
        show_header
        list_gateways
        ;;
    info)
        get_gateway_info "$2"
        ;;
    start)
        start_gateway "$2"
        ;;
    stop)
        stop_gateway "$2"
        ;;
    ssh)
        ssh_gateway "$2"
        ;;
    config)
        configure_gateway "$2" "$3" "$4"
        ;;
    label)
        label_gateway "$2" "$3"
        ;;
    interactive)
        interactive_menu
        ;;
    help)
        echo "Tide Gateway VM Manager"
        echo ""
        echo "Usage:"
        echo "  $0                           Interactive menu"
        echo "  $0 list                      List all gateways"
        echo "  $0 info <vm-name>            Get gateway info"
        echo "  $0 start <vm-name>           Start gateway"
        echo "  $0 stop <vm-name>            Stop gateway"
        echo "  $0 ssh <vm-name>             SSH into gateway"
        echo "  $0 config <vm> <mode> <sec>  Configure gateway"
        echo "  $0 label <old> <new>         Rename gateway"
        echo ""
        echo "Examples:"
        echo "  $0 start Tide-Gateway"
        echo "  $0 config Tide-Gateway killa-whale hardened"
        echo "  $0 label Tide-Gateway Tide-Production"
        ;;
    *)
        echo "Unknown command: $CMD"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
