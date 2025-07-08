#!/bin/bash

output_file="valid_keys.txt"
> "$output_file"

echo "===================================="
echo "🧠 OpenAI API Key Verifier"
echo "===================================="
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
        echo "❌ File target.txt not found."
        exit 1
    fi
    mapfile -t keys < target.txt
else
    echo "❌ Invalid option."
    exit 1
fi

echo "[*] Verifying ${#keys[@]} API key(s)..."

for key in "${keys[@]}"; do
    echo -n "[*] Testing $key ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json")

    case $response in
        200)
            echo "✅ VALID"
            echo "$key" >> "$output_file"
            ;;
        401)
            echo "❌ Invalid"
            ;;
        403)
            echo "🚫 Forbidden (maybe expired or disabled)"
            ;;
        429)
            echo "⏳ Rate Limited (but VALID)"
            echo "$key (RATE LIMITED)" >> "$output_file"
            ;;
        *)
            echo "⚠️ Unknown Status: $response"
            ;;
    esac
done

echo "✅ Done. Valid keys saved to: $output_file"
