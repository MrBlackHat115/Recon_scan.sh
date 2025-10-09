#!/usr/bin/env bash
# Usage: ./recon_scan.sh
# Note: This script is using nmap and may require sudo to execute.

read -rp "Enter target IP address: " IP
read -rp "What wordlist do you want to use for directory scan (full path): " wordlist
read -rp "What do you want your nmap output file to be named (e.g. nmap_results.txt): " file_name
read -rp "What do you want your dir scan output file to be named (e.g. dir_results.txt): " dir_file

# Quick ping check
if ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
    echo "[*] $IP is reachable!"
else
    echo "[!] $IP is not reachable or doesn't exist!"
    exit 1
fi

# Run nmap once, save human-readable nmap output to the user file and also capture a log
echo "[*] Running nmap against $IP -> $file_name (nmap_results.txt)"
if command -v nmap >/dev/null 2>&1; then
    nmap -A -sS -T3 "$IP" -oN "$file_name" > nmap_results.txt 2>&1
    rc=$?
    if [ $rc -eq 0 ]; then
        echo "Nmap scan succeeded."
    else
        echo "Nmap finished with exit code $rc. See nmap_results.txt for details."
        # continue to directory scan even if nmap returned non-zero
    fi
else
    echo "nmap not found. Please install nmap and try again."
    exit 1
fi

# Directory discovery tool selection
echo "Pick a directory discovery tool:"
PS3="Choose tool: "
options=("gobuster" "dirb" "ffuf" "quit")
select opt in "${options[@]}"; do
    case "$opt" in
        gobuster)
            if ! command -v gobuster >/dev/null 2>&1; then
                echo "[!] gobuster not installed. Install it or choose another tool."
                break
            fi
            echo "[*] Running gobuster (output -> $dir_file)..."
            # gobuster has -o option to write output
            gobuster dir -u "http://$IP/" -w "$wordlist" -o "$dir_file"
            echo "[+] gobuster finished. Results -> $dir_file"
            break
            ;;
        dirb)
            if ! command -v dirb >/dev/null 2>&1; then
                echo "[!] dirb not installed. Install it or choose another tool."
                break
            fi
            echo "[*] Running dirb (output -> $dir_file)..."
            # dirb prints to stdout, so redirect to file
            dirb "http://$IP" "$wordlist" > "$dir_file" 2>&1
            echo "[+] dirb finished. Results -> $dir_file"
            break
            ;;
        ffuf)
            if ! command -v ffuf >/dev/null 2>&1; then
                echo "[!] ffuf not installed. Install it or choose another tool."
                break
            fi
            echo "[*] Running ffuf (output -> $dir_file)..."
            # ffuf supports -o to write output (json/csv etc). Use default output option if available.
            ffuf -u "http://$IP/FUZZ" -w "$wordlist" -o "$dir_file"
            echo "[+] ffuf finished. Results -> $dir_file"
            break
            ;;
        quit)
            echo "Quitting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Pick a number from the list."
            ;;
    esac
done

echo "[*] All done."
exit 0