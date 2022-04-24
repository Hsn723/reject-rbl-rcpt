#!/bin/bash -eux

$(pwd)/target/debug/reject-rbl-rcpt &
PID=$(echo $!)

trap 'kill -SIGINT ${PID}' SIGINT SIGTERM EXIT

sleep 5

for test_file in $(find tests/ -name "*.lua"); do
    miltertest -s ${test_file}
done

exit 0
