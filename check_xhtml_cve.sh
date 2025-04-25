#!/bin/bash
set -e

openshift_remote="openshift"
package="golang.org/x/net/html"
repos=$(cat /Users/nbrubake/Documents/investigations/cve-2024-45338/repos)
output=/tmp/cve-check.txt

rm ${output}; touch ${output}

for repo in ${repos}
do
    echo "--> ${repo}" | tee -a ${output}
    cd /Users/nbrubake/projects/${repo}
    for i in {12..19} # release range to check
    do

      branch="release-4.${i}"
      ref="${openshift_remote}/${branch}"

      echo "--->"

      echo "fetching ref: ${ref}"
      git fetch ${openshift_remote} ${branch}

      echo "switching to ref: ${ref}" | tee -a ${output}
      git checkout ${ref}

      go mod why -m ${package} >> ${output}

      echo "----------------"
    done

    echo "\n" >> ${output}
done
