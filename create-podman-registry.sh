#!/bin/zsh
# Taken from https://gist.github.com/thomasdarimont/5db95906158745bac779b760fbf6999f
reg_name='kind-registry'
# On macOS, AirPlay receiver listens on 5000 by default
reg_port='5001'
running="$(podman inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  podman run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi
