#!/bin/bash
#
# Copyright (c) 2023 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

set -o pipefail

# General env
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/../../metrics/lib/common.bash"

PAYLOAD_ARGS="${PAYLOAD_ARGS:-tail -f /dev/null}"
DOCKERFILE="${SCRIPT_PATH}/Dockerfile"
IMAGE="docker.io/library/local-stressng:latest"
CONTAINER_NAME="${CONTAINER_NAME:-stressng_test}"

function main() {
	local cmds=("docker")

	init_env
	check_cmds "${cmds[@]}"
	check_ctr_images "${IMAGE}" "${DOCKERFILE}"
	sudo -E ctr run -d --runtime "${CTR_RUNTIME}" "${IMAGE}" "${CONTAINER_NAME}" sh -c "${PAYLOAD_ARGS}"

	# Run 1 iomix stressor (mix of I/O operations) for 20 seconds with verbose output
	info "Running iomix stressor test"
	IOMIX_CMD="stress-ng --iomix 1 -t 20 -v"
	sudo -E ctr t exec --exec-id 1 "${CONTAINER_NAME}" sh -c "${IOMIX_CMD}"

	# Run cpu stressors and virtual memory stressors for 5 minutes
	info "Running memory stressors for 5 minutes"
	MEMORY_CMD="stress-ng --cpu 2 --vm 4 -t 5m"
	sudo -E ctr t exec --exec-id 2 "${CONTAINER_NAME}" sh -c "${MEMORY_CMD}"

	# Run shared memory stressors
	info "Running 8 shared memory stressors"
	SHARED_CMD="stress-ng --shm 0"
	sudo -E ctr t exec --exec-id 3 "${CONTAINER_NAME}" sh -c "${SHARED_CMD}"

	clean_env_ctr
}

main "$@"
