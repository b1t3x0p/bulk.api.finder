#!/bin/bash

output_file="valid_keys.txt"
> "$output_file"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}===================================="
echo "🧠 OpenAI API Key Verifier"
echo -e "====================================${NC}"
echo "1) Enter keys manually"
echo "2) Load from file (target.txt)"
read -p "Choose option (1/2): " option

if [[ "$option" == "1" ]]; then
    echo "Enter API keys one per line (type 'end' to finish):"
    keys=()
    while true; do
        read -p "> " key
        [[ "$key" == "end" ]] && break
        [[ -z "$key" ]] && continue
        keys+=("$key")
    done
elif [[ "$option" == "2" ]]; then
    if [[ ! -f "target.txt" ]]; then
        echo -e "${RED}❌ File target.txt not found.${NC}"
        exit 1
    fi
    mapfile -t keys < target.txt
else
    echo -e "${RED}❌ Invalid option.${NC}"
    exit 1
fi

echo "[*] Verifying ${#keys[@]} API key(s)..."

for key in "${keys[@]}"; do
    echo -ne "[*] Testing ${key:0:8}************ ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json")

    case $response in
        200)
            echo -e "${GREEN}✅ VALID ➤ $key${NC}"
            echo "$key" >> "$output_file"
            echo -e "${GREEN}🎯 Successfully Got Live!${NC}"
            ;;
        401)
            echo -e "${RED}❌ INVALID${NC}"
            ;;
        403)
            echo -e "${RED}🚫 Forbidden (maybe expired or disabled)${NC}"
            ;;
        429)
            echo -e "${GREEN}⏳ Rate Limited (but VALID) ➤ $key${NC}"
            echo "$key (RATE LIMITED)" >> "$output_file"
            ;;
        *)
            echo -e "${RED}⚠️ Unknown Status: $response${NC}"
            ;;
    esac
done

echo -e "${GREEN}✅ Done. Valid keys saved to: $output_file${NC}"

