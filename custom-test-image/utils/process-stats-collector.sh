#!/bin/bash

# Check if a PID was provided as a command-line argument
if [ -z "$1" ]; then
    echo "Usage: $0 <process_id>"
    exit 1
fi

# Get the process ID
pid=$1

# Check if the process exists
if ! ps -p $pid &> /dev/null; then
    echo "Process $pid does not exist."
    exit 1
fi

# Get the output file name
output_file="process-stats-$pid.csv"

# Write the header row
echo "Timestamp,PID,CPU%,MEM(MB),MINOR_FAULTS,MAJOR_FAULTS,ANON_RSS(MB),ANON_FILE(MB)" > "$output_file"

# Run the script every 1 second and write the output to the file
while true; do
    # Get the current timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Get page faults
    page_fault_info=$(ps -p $pid -o minflt,majflt --no-headers)
    IFS=' ' read -ra page_fault_array <<< "$page_fault_info"
    minor_faults=${page_fault_array[0]}
    major_faults=${page_fault_array[1]}
    total_faults=$((minor_faults + major_faults))

    # Get anonymous memory usage
    anon_rss=$(grep "^RssAnon:" /proc/$pid/status | awk '{print $2/1024}')
    anon_file=$(grep "^RssFile:" /proc/$pid/status | awk '{print $2/1024}')

    # Get CPU usage
    cpu_usage=$(ps -p $pid -o %cpu --no-headers)

    # Get memory usage
    mem_usage=$(ps -p $pid -o rss --no-headers | awk '{print $1/1024}')

    # Write the data to the CSV file
    echo "$timestamp,$pid,$cpu_usage%,$mem_usage,$minor_faults,$major_faults,$anon_rss,$anon_file" >> "$output_file"

    sleep 1
done
