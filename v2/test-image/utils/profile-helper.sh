#!/bin/bash

# Check if a PID and duration were provided as command-line arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <duration_in_seconds> <output file> <delay in seconds"
    exit 1
fi

# Get the Java process ID and duration
OS_PID=$1
DURATION=$2
FILE_NAME=$3
DELAY=$4

echo "Sleeping ${DELAY} seconds..."
sleep ${DELAY}

# Check if the Java process exists
if ! ps -p ${OS_PID} &> /dev/null; then
    echo "Java process ${OS_PID} does not exist."
    exit 1
fi

# Set the output file name
OUTPUT_FILE="${FILE_NAME}"

# Download and extract the async-profiler if it's not already available
if ! command -v async-profiler &> /dev/null; then
    echo "Downloading and extracting async-profiler..."
    curl -LO https://github.com/jvm-profiling-tools/async-profiler/releases/download/v2.8.1/async-profiler-2.8.1-linux-x64.tar.gz
    tar -xzf async-profiler-2.8.1-linux-x64.tar.gz
fi

# Run the async-profiler to generate the flame graph
echo "Generating flame graph for Java process ${OS_PID} for ${DURATION} seconds..."
./async-profiler-2.8.1-linux-x64/profiler.sh -d ${DURATION} -f "${OUTPUT_FILE}" -s -o flamegraph ${OS_PID}

echo "Flame graph generated: ${OUTPUT_FILE}"
