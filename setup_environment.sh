#!/bin/bash
#
# https://gist.github.com/suppaduppax/e7084b1a7b538c08b95a43b03d7430f7
#
# An automated setup of environment which does the following things:
# - creates a python virtual environment (venv)
# - pip installs ansible
# - installs ansible galaxy requirements
# - installs pip requirements
# - automatically activates the venv after creation
#
# If the virtual environment path is detected, it will skip installation and instead activate the venv

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# virtual environment directory
# uses current directory + _venv and replaces all dashes with underscores: - => _
# change this to a specific dir if required
venv_dir="$(basename ${script_dir} | tr - _)_venv"

galaxy_req="galaxy_requirements.yml"
pip_req="pip_requirements.txt"

print_help () {
  # show help
  echo "
Setup Environment
-----------------
Usage:
source setup_environment.sh             Must use source if running without any paramaters to properly
                                        activate virtual environment

bash setup_environment.sh [OPTIONS]     Using 'bash' or './' is okay when using -r, -g, -p options
./setup_environment.sh [OPTIONS]

Description:
Automatically set up ansible environment which includes:
  - creating a python virtual environment (venv)
  - installing ansible through pip
  - installing ansible-galaxy requirements (looks for file '${galaxy_req}'), edit \$galaxy_req in
    script to change)
  - installing python pip requirements (looks for file '${pip_req}', edit \$pip_req in script to 
    chabnge) 
  - activating venv
Running the script with -r, -g, -p will install requirements only. See below for reference.

Option                                  Description
-r                                      Only install ansible-galaxy and python pip requirements
-g                                      Only install ansible-galaxy requirements
-p                                      Only install python pip requirements
-h                                      Print this help screen
"

}


activate_venv () {
  log "Activating venv '${venv_dir}'"
  source "${venv_dir}/bin/activate"
}

log () {
  echo -e "\033[0;32m[$(date +%T)] ${1}\033[0m"
}

error () {
  echo -e "\033[0;31m[$(date +%T)] ${1}\033[0m"
}

install_galaxy_req () {
  log "Installing ansible-galaxy requirements: '${galaxy_req}'"
  if [ -f "${galaxy_req}" ]; then
    ansible-galaxy install -r "${galaxy_req}"
  else
    error "Ansible-galaxy requirements file not found. Skipping..."
  fi
}

install_pip_req () {
  log "Installing python pip requirements: '${pip_req}'"
  if [ -f "${pip_req}" ]; then
    pip install -r "${pip_req}"
  else
    error "Python pip requirements file not found. Skipping..."
  fi
}

if [[ -z "${1}" ]]; then
  # Ensure script is run using 'source' command instead of 'bash <script_name>' or .'/<script_name>'
  if [[ "${0}" != "-bash" ]]; then
    error "Script must be run using 'source $(basename $0)'"
    exit 1
  fi

  if [ ! -d "${venv_dir}" ]; then
    log "Virtual environment '${venv_dir}' not found. Creating..."
    python3 -m venv "${venv_dir}"
    activate_venv

    log "Installing ansible"
    pip install ansible   

    install_galaxy_req
    install_pip_req

    log "Virtual environment activated. Use 'deactivate' to exit venv."

  else
    # Check to see if venv has already been activated
    if [ -z "${VIRTUAL_ENV}" ] || [[ ! "${script_dir}/${venv_dir}" == "${VIRTUAL_ENV}" ]]; then
      activate_venv
      log "Virtual environment activated. Use 'deactivate' to exit venv."

    else
      error "Virtual environment '${venv_dir}' already activated"   

    fi

  fi

elif [[ "${1}" == "-r" ]]; then
  install_galaxy_req
  install_pip_req

elif [[ "${1}" == "-g" ]]; then
  install_galaxy_req

elif [[ "${1}" == "-p" ]]; then
  install_pip_req

else
  print_help
fi

echo ""