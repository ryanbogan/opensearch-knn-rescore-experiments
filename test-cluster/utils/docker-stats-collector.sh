#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker to use this script."
    exit 1
fi

# Check if a container ID or name was provided as a command-line argument
if [ -z "$1" ]; then
    echo "Usage: $0 <container_id_or_name>"
    exit 1
fi

# Get the container ID or name
container_id="$1"

# Check if the container exists
if ! docker inspect "$container_id" &> /dev/null; then
    echo "Container $container_id does not exist."
    exit 1
fi

# Get the output file name
output_file="/tmp/profiles/stats-$container_id.csv"

# Write the column names to the file
echo "Timestamp,Memory Usage (MB),Memory Limit (MB),Memory Usage (%),CPU Usage (%),Read Throughput (MB/s),Write Throughput (MB/s)" > "$output_file"

while true; do
    # Get memory usage
    memory_usage=$(docker stats "$container_id" --no-stream --format "{{.MemUsage}}" | awk -F'/' '{print $1}' | sed 's/[^0-9]*//g')
    memory_limit=$(docker stats "$container_id" --no-stream --format "{{.MemUsage}}" | awk -F'/' '{print $2}' | sed 's/[^0-9]*//g')
    memory_percent=$((memory_usage * 100 / memory_limit))

    # Get CPU usage
    cpu_usage=$(docker stats "$container_id" --no-stream --format "{{.CPUPerc}}" | sed 's/%//')

    # Get disk throughput
    disk_stats=$(docker stats "$container_id" --no-stream --format "{{.BlockIO}}")
    read_write=$(echo "$disk_stats" | tr -s ' ')
    read_throughput=$(echo "$read_write" | cut -d '/' -f 1 | tr -d 'A-Z a-z' | sed 's/[^0-9.]//g')
    write_throughput=$(echo "$read_write" | cut -d '/' -f 2 | tr -d 'A-Z a-z' | sed 's/[^0-9.]//g')

    # Get the current timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Write the data to the CSV file
    echo "$timestamp,$memory_usage,$memory_limit,$memory_percent,$cpu_usage,$read_throughput,$write_throughput" >> "$output_file"

    sleep 1
done
