#!/usr/bin/env bash
openshift_remote="openshift"
begin=12
end=19
branch_prefix="release-4."

################

check_module() {
    local module=$1
    if go mod why -m "$module" | grep -qv "(main module does not need module"; then
        echo "Module $module is needed by this release. Inspecting further with callgraph ..."

       if ! output=$(callgraph -format=digraph "${MAIN_ENTRYPOINT}" 2>&1); then
            echo ""
            echo "FATAL ERROR: callgraph failed for ${MAIN_ENTRYPOINT}, this means the MAIN_ENTRYPOINT you set for this repo doesn't exist."
            echo "The entrypoint depends on which repo you are checking, there can be multiple entrypoints for a repo, each 'package main' is an entrypoint."
            echo "If there is only one main package and it is in the root of the repo, then the entrypoint will be *.go"
            git switch ${initial_branch}
            exit 1
        fi

        if echo "$output" | digraph nodes | grep jwt | grep -q ParseUnverified; then
            echo "Found a match for ParseUnverified in the exection graph, THIS RELEASE IS VULNERABLE TO CVE-2025-30204"
        else
            echo "No match found for ParseUnverified in the exection graph for ${MAIN_ENTRYPOINT}. ENTRYPOINT NOT VULNERABLE, remember to check all entrypoints"
        fi

        return 0
    else
        echo "Module $module is NOT needed by this release. Skipping further checks."
        return 0
    fi
}

if [[ -z "${MAIN_ENTRYPOINT}" ]]; then
  echo "MAIN_ENTRYPOINT env variable not found, please set it before running this script"
  exit 1
fi

initial_branch=$(git branch --show-current)

for (( i=$end; i>=$begin; i-- )) # release range to check newest to oldest
do

  branch="${branch_prefix}${i}"
  ref="${openshift_remote}/${branch}"

  echo "--------------->"

  echo "fetching ref: ${ref}"
  git fetch ${openshift_remote} ${branch} > /dev/null 2>&1 || echo "Error: Failed to fetch ${ref}, do you have an 'ocp' git remote set up?"

  echo "switching to ref: ${ref}"
  git checkout ${ref} > /dev/null 2>&1 || echo "Error: Failed to checkout ${ref}" && \


  check_module "github.com/golang-jwt/jwt/v4"
  check_module "github.com/golang-jwt/jwt/v5"

done

git switch ${initial_branch}
