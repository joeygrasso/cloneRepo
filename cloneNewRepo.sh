#!/bin/bash
#
# Clone New Repo with options over SSH
set -eou pipefail

VERSION="1.0.0"

cd "$(dirname "$0")/"
dir_root=$(pwd)

source ${dir_root}/bash_helpers

usage() {
    cat <<EOF
USAGE: $0 [options]
This script will clone a repo, optionally add a remote called
upstream, and optionally add an alias to ~/.repo-aliases.

OPTIONS:
  -h, --help        Show this message
  -a, --alias       Create a repo alias.
  -k, --key         Clone over SSH using a key. Default is HTTPS.
  -n, --repo-name   Name of repo to be cloned.
  -o, --repo-owner  Repository owner of repo to be cloned.
  -p, --clone-path  Clone destination path. Default is a user's home
                    directory.
  -r, --remote      Remote repository owner usually a github user or
                    organization.
  -s, --source      Source of repo. Default github.com.
  -v, --version     Show version and exit.

EOF
}

# Clone Repo
clone_repo() {

  log "cloning: ${FULL_CLONE_URL}"
  if !(git clone ${FULL_CLONE_URL} ${CLONE_PATH}/${REPO_NAME}); then
    fail "could not clone ${REPO_NAME}"
    exit 1
  fi
  success "Successfully cloned ${REPO_OWNER}/${REPO_NAME}..."
}

# Add Remote
add_remote() {
  log "Adding remote: ${REPO_REMOTE_OWNER}/${REPO_NAME}..."

  # Change from working directory into cloned repo
  cd ${CLONE_PATH}/${REPO_NAME}

  if !(git remote add upstream ${FULL_CLONE_URL}); then
    fail "could not add remote ${FULL_CLONE_URL}"
    exit 1
  fi
  success "Successfully added remote: ${REPO_REMOTE_OWNER}/${REPO_NAME}..."
  
  # Go one level higher in the dir tree in case we want to alias here
  cd ..
}

# # Add Alias
add_repo_alias() {
  log "Adding ${REPO_NAME} alias..."
  echo "### ${REPO_NAME} alias added by $0 on $(date +%m-%d-%y)
alias repo-${REPO_NAME}=\"cd ${CLONE_PATH}/${REPO_NAME}\"" >> ${HOME}/.repo-aliases

  success "Successfully added alias: repo-${REPO_NAME}..."
}


### Main Execution:

# Check for git. Fail fast.
check_installed git

# Arguments
ALIAS=
CLONE_PATH=${HOME}
REPO_SOURCE="github.com"
REPO_OWNER=
REPO_NAME=
REPO_REMOTE_OWNER=
SSH=

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -a|--alias)
      ALIAS=true;;
    -k|--key)
      SSH=true;;
    -n|--repo-name)
      REPO_NAME="$2"; shift;;
    -o|--repo-owner)
      REPO_OWNER="$2"; shift;;
    -p|--clone-path)
      CLONE_PATH="$2"; shift;;
    -r|--remote)
      REPO_REMOTE_OWNER="$2"; shift;;
    -s|--source)
      REPO_SOURCE="$2"; shift;;
    -v|--version)
      VERSION_FLAG=true;;
    *)
      fail "Unsupported flag detected."
      exit 1
  esac
  shift;
done

# Output Version and Exit
if [[ ${VERSION_FLAG} ]]; then
  echo "v${VERSION}"
  exit 0
fi

# Get Protocol and Separator
if [[ ${SSH} ]]; then
  REPO_PROTOCOL="git@"
  REPO_SEPARATOR=":"
else
  REPO_PROTOCOL="https://"
  REPO_SEPARATOR="/"
fi

# URL for all git operations
FULL_CLONE_URL="${REPO_PROTOCOL}${REPO_SOURCE}${REPO_SEPARATOR}${REPO_OWNER}/${REPO_NAME}.git"

# Attempt clone
clone_repo

# If remote is provided, add.
if ! [[ -z ${REPO_REMOTE_OWNER} ]]; then
  add_remote
else
  log "Remote not provided."
fi

# If -a or --alias
if [[ ${ALIAS} ]]; then
  if [[ $(check_file_exists "${HOME}/.repo-aliases") != "found" ]]; then
    warn "${HOME}/.repo-aliases not found. Creating file..."
    touch "${HOME}/.repo-aliases"
    echo "Add `source ${HOME}/.repo-aliases` to shell file"
  fi
  add_repo_alias
  source ${HOME}/.repo-aliases
fi
