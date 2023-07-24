#!/bin/bash

# Function to perform an nmap scan
function run_nmap_scan() {
    local ip_range="$1"
    local output_file="$2"
    nmap -sP "$ip_range" -oG "$output_file"
}

# Function to extract alive hosts from the nmap scan
function extract_alive_hosts() {
    local input_file="$1"
    grep -E 'Host: [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$input_file" | awk '{print $2}'
}

# Function to perform a port scan
function run_port_scan() {
    local ip="$1"
    local output_file="$2"
    nmap -p- "$ip" -oG "$output_file"
}

# Function to run -A scan for each open port
function run_a_scan() {
    local ip="$1"
    local ports_file="$2"
    local open_ports=$(grep -Eo '[0-9]+/open' "$ports_file" | grep -Eo '[0-9]+' | tr '\n' ',' | sed 's/,$//')

    local output_file="scan_results_${ip}_ports.txt"
    nmap -A -p"$open_ports" "$ip" -oN "$output_file"

}

# Function to combine all -A scan output files into one
function combine_scan_results() {
    local output_file="combined_scan_results.txt"
    cat scan_results_* > "$output_file"
    echo "Combined scan results saved to: $output_file"
}

# Input IP range
read -p "Enter IP range to scan (e.g. 192.168.0.1/24): " ip_range

# Run nmap -sn scan
nmap_output_file="nmap_output.txt"
run_nmap_scan "$ip_range" "$nmap_output_file"

# Extract alive hosts
alive_hosts_file="alive_hosts.txt"
extract_alive_hosts "$nmap_output_file" > "$alive_hosts_file"

# Perform port scan for each alive host
while IFS= read -r host; do
    port_scan_output_file="port_scan_$host.txt"
    run_port_scan "$host" "$port_scan_output_file"
    
    # Run -A scan for each port
    run_a_scan "$host" "$port_scan_output_file"
done < "$alive_hosts_file"

combine_scan_results
