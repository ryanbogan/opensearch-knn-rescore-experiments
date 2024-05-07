#!/bin/bash

# Sleep for 30 seconds so osb process can start
sleep 30

# Check if a PID and duration were provided as command-line arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <java_process_id> <duration_in_seconds>"
    exit 1
fi

# Get the Java process ID and duration
java_pid=$1
duration=$2

# Check if the Java process exists
if ! ps -p $java_pid &> /dev/null; then
    echo "Java process $java_pid does not exist."
    exit 1
fi

# Set the output file name
output_file="/profiles/flamegraph.html"

# Download and extract the async-profiler if it's not already available
if ! command -v async-profiler &> /dev/null; then
    echo "Downloading and extracting async-profiler..."
    curl -LO https://github.com/jvm-profiling-tools/async-profiler/releases/download/v2.8.1/async-profiler-2.8.1-linux-x64.tar.gz
    tar -xzf async-profiler-2.8.1-linux-x64.tar.gz
fi

# Run the async-profiler to generate the flame graph
echo "Generating flame graph for Java process $java_pid for $duration seconds..."
./async-profiler-2.8.1-linux-x64/profiler.sh -d $duration -f "$output_file" -s -o flamegraph $java_pid

echo "Flame graph generated: $output_file"
