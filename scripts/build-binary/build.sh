#!/usr/bin/env bash

# Copyright Markus Binsteiner, 2021
# License: Parity License, v7.0 ( https://paritylicense.com/versions/7.0.0 )

DEFAULT_PYTHON_VERSION="3.9.2"
DEFAULT_PYINSTALLER_VERSION="4.2"

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function command_exists {
   type "$1" > /dev/null 2>&1 ;
}

# mac sometimes does not have 'realpath' available
if ! command_exists realpath; then

  function realpath() {

      local _X="$PWD"
      local _LNK=$1
      cd "$(dirname "$_LNK")"
      if [ -h "$_LNK" ]; then
          _LNK="$(readlink "$_LNK")"
          cd "$(dirname "$_LNK")"
      fi
      local _basename=$(basename "$_LNK")

      if [[ "${_basename}" = "/" ]]; then
          _basename=""
      fi
      if [[ "${PWD}" = "/" ]]; then
          echo "/${_basename}"
      else
          echo "$PWD/${_basename}"
      fi

      cd "$_X"

  }

fi


function ensure_python () {

    local python_version="${1}"

    export PATH="${HOME}/.pyenv/bin:$PATH"

    # pyenv
    if ! command_exists pyenv; then

        if command_exists curl; then
            curl https://pyenv.run | bash
        elif command_exists wget; then
            wget -O- https://pyenv.run | bash
        else
            echo "Can't install pyenv. Need wget or curl."
            exit 1
        fi
    fi

    local python_path="${HOME}/.pyenv/versions/${python_version}"
    if [ -n "${python_version}" ]; then
      # python version
      if [ ! -e "${python_path}" ]; then
          pyenv update
          env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "${python_version}"
          if [ $? -ne 0 ]; then
            echo "Can't install requested Python version: ${python_version}"
#            exit 1
          fi
          eval "$(pyenv init -)"
          eval "$(pyenv virtualenv-init -)"

      fi
    else
      echo "No Python version provided"
      exit 1
    fi
}

function get_python_path () {

    local python_version="${1}"

    local python_path="${HOME}/.pyenv/versions/${python_version}/bin/python"
    echo ${python_path}

}


function ensure_virtualenv () {

   local python_path="${1}"
   local python_version="${2}"
   local auto_venv_name="${3}"

   local virtualenv_path="${HOME}/.cache/frkl-build-envs/${auto_venv_name}-${python_version}"
   if [ ! -e "${virtualenv_path}/bin/activate" ]; then
     cmd=( "${python_path}" "-m" "venv" "${virtualenv_path}" )
     "${cmd[@]}"
   fi

    echo ${virtualenv_path}
}


function install_requirements () {

    local pyinstaller_version="${1}"
    local requirements_file="${2}"

    pip install -U pip setuptools wheel
    pip install "pyinstaller==${pyinstaller_version}"

    if [ -n "${requirements_file}" ]; then
        echo "installing dependencies from: ${requirements_file}"
        pip install -U --extra-index-url https://gitlab.com/api/v4/projects/25344049/packages/pypi/simple -r "${requirements_file}"
    fi

    pip install -U --upgrade-strategy eager --extra-index-url https://gitlab.com/api/v4/projects/25344049/packages/pypi/simple 'frkl.project[all]'

    rm -rf dist/*whl
    python setup.py bdist_wheel
    local wheel_file=$(ls dist/*whl)
#    pip install -U --upgrade-strategy eager --extra-index-url https://gitlab.com/api/v4/projects/25344049/packages/pypi/simple --force-reinstall "${wheel_file}[all]"   - TODO: is 'force-reinstall necessary?
    pip install -U --upgrade-strategy eager --extra-index-url https://gitlab.com/api/v4/projects/25344049/packages/pypi/simple "${wheel_file}[all]"

    echo " --> dependencies installed"

}

function in_venv() {
   python -c 'import sys; print("true" if (hasattr(sys, "real_prefix") or (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix)) else "false")'
}

function in_conda_env() {
  python -c 'import os; print("true" if os.environ.get("CONDA_DEFAULT_ENV", None) is not None else "false")'
}

function using_system_python() {
  if [ "$(in_venv)" = true ]; then
    echo "false"
  elif [ "$(in_conda_env)" = true ]; then
    echo "false"
  else
    echo "true"
  fi
}


function build_artifact () {

    local python_type="${1}"
    local project_root="${2}"
    local build_dir="${3}"
    local python_version="${4}"
    local pyinstaller_version="${5}"
    local requirements_file="${6}"
    local output_dir="${7}"
    local spec_file="${8}"


    local auto_venv_name="$(basename ${project_root})-build"

    local python_path=""
    local venv_activate_path=""

    if [ "${python_type}" = "current-env" ];
    then
        if ! command_exists python && ! command_exists python3;
        then
          echo "Python not installed and 'current-env' python_type selected, can't proceed..."
          exit 3
        fi

        if [ "$(using_system_python)" = true ];
        then
          echo "Not in virtual- or conda-env and python_type 'current-env' selected, can't proceed..."
          exit 3
        fi

        python_path=$(which python)
        venv_activate_path="$(dirname ${python_path})/activate"

    elif [ "${python_type}" = "system" ];
    then

        if ! command_exists python && ! command_exists python3;
        then
          echo "Python not installed and 'system' python_type selected, can't proceed..."
          exit 3
        fi

        if [ "$(using_system_python)" != true ];
        then
          echo "In a virtual- or conda-env and 'system' python_type selected, can't proceed..."
          exit 3
        fi

        python_path=$(which python)

    elif [ "${python_type}" = "auto" ];
    then

        if ! command_exists python && ! command_exists python3;
        then
            echo "installing python version ${python_version}..."
            ensure_python "${python_version}"
            pyenv_python_path=$(get_python_path "${python_version}")
            echo " -> Python ${python_version} installed"
            echo
            echo "creating virtualenv ${auto_venv_name} .."
            venv_activate_path="$(ensure_virtualenv ${pyenv_python_path} ${python_version} ${auto_venv_name})/bin/activate"
            python_path="$(dirname venv_activate_path)/python"
            echo " -> virtualenv exits: ${venv_path}"
            echo
        elif [ "$(using_system_python)" = true ];
        then
            echo "ensuring virtualenv ${auto_venv_name} exists.."
            venv_activate_path="$(ensure_virtualenv $(which python) ${python_version} ${auto_venv_name})/bin/activate"
            python_path="$(dirname ${venv_activate_path})/python"
            echo " -> virtualenv exits: ${venv_activate_path}"
            echo
        else
          # means we are in a virtual or conda env
            python_path=$(which python)
            if [ "$(using_system_python)" != true ];
            then
              venv_activate_path="$(dirname ${python_path})/activate"
            fi
        fi

    elif [ "${python_type}" = "pyenv" ];
    then
      echo "making sure Python version is available..."
      ensure_python "${python_version}"
      pyenv_python_path=$(get_python_path "${python_version}")
      echo " -> Python ${python_version} exists"
      echo

      echo "making sure virtualenv ${auto_venv_name} exists..."
      venv_activate_path="$(ensure_virtualenv ${pyenv_python_path} ${python_version} ${auto_venv_name})/bin/activate"
      python_path="$(dirname venv_activate_path)/python"
      echo " -> virtualenv exits: ${venv_path}"
      echo
    elif [ "${python_type}" = "conda" ];
    then
        echo "python_type 'conda' not supported yet."
        exit 3
    else
        echo "python_type '${python_type}' not supported."
        exit 3
    fi


    echo "using python: ${python_path}"
    echo "using venv: ${venv_activate_path}"
    echo

    cd "${project_root}"

    local target="${output_dir}/${OSTYPE}"

    mkdir -p "${build_dir}"

    if [ -n "${venv_activate_path}" ];
    then
        source ${venv_activate_path}
    fi

    echo "preparing build"
    install_requirements "${pyinstaller_version}" "${requirements_file}"

    mkdir -p "${output_dir}"

    echo "building package"

    local temp_dir="${build_dir}/build-${RANDOM}"
    mkdir -p "${temp_dir}"

    frkl-project metadata print --output .frkl/project.json
    frkl-project metadata print-pyinstaller-data --output .frkl/pyinstaller

    pyinstaller --clean -y --dist "${target}" --workpath "${temp_dir}" "${spec_file}"

    rm -rf "${temp_dir}"

    if [ -n "${venv_activate_path}" ];
    then
        deactivate
    fi

    echo "  -> package built"

}


function main () {

    local python_type="${1}"
    local project_root="${2}"
    local build_dir="${3}"
    local python_version="${4}"
    local pyinstaller_version="${5}"
    local requirements_file="${6}"
    local output_dir="${7}"
    local spec_file="${8}"


    if [ -z "${DOCKER_BUILD}" ]; then
        DOCKER_BUILD=false
    fi

    if [ "${DOCKER_BUILD}" != true ]; then

           build_artifact "${python_type}" "${project_root}" "${build_dir}" "${python_version}" "${pyinstaller_version}" "${requirements_file}" "${output_dir}" "${spec_file}"

    else
            # TODO: fix this
            echo "Docker build currently not supported."
            exit 1
#            docker run -v "${THIS_DIR}/..:/src/" registry.gitlab.com/freckles-io/freckles-build "${entrypoint}"

    fi
}

while [[ -n "$1" ]]; do
  case "$1" in
  --project-root)
    shift
    PROJECT_ROOT="${1}"
    ;;
  --build-dir)
    shift
    BUILD_DIR="${1}"
    ;;
  --pyinstaller-version)
    shift
    PYINSTALLER_VERSION="${1}"
    ;;
  --requirements)
    shift
    REQUIREMENTS_FILE="${1}"
    ;;
  --output-dir)
    shift
    OUTPUT_DIR="${1}"
    ;;
  --spec-file)
    shift
    SPEC_FILE="${1}"
    ;;
  --python-type)
    shift
    PYTHON_TYPE="${1}"
    ;;
  --python-version)
    shift
    PYTHON_VERSION="${1}"
    ;;
  --)
    shift
    break
    ;;
  -*|--*=) # unsupported flags
    echo "Error: Invalid argument '${1}'" >&2
    exit 1
    ;;
  esac
  shift
done

echo

if [ -z "${PROJECT_ROOT}" ]
then
   PROJECT_ROOT=$(pwd)
fi
if [ ! -d "${PROJECT_ROOT}" ]
then
  echo "project root '${PROJECT_ROOT} does not exist or is not directory"
  exit 1
fi
PROJECT_ROOT=$(realpath "${PROJECT_ROOT}")

if [ -z "${BUILD_DIR}" ]
then
  BUILD_DIR="/tmp"
fi
mkdir -p ${BUILD_DIR}
if [ ! -d "${BUILD_DIR}" ]
then
  echo "can't create build dir '${BUILD_DIR}"
  exit 1
fi
BUILD_DIR=$(realpath "${BUILD_DIR}")

if [ -z "${PYINSTALLER_VERSION}" ]
then
  PYINSTALLER_VERSION="${DEFAULT_PYINSTALLER_VERSION}"
fi

if [ -n "${REQUIREMENTS_FILE}" ]
then
  if [[ ! -f "${REQUIREMENTS_FILE}" ]]; then
    echo "Requirements file does not exist: ${REQUIREMENTS_FILE}"
    exit 1
  fi
fi
if [ -f "${REQUIREMENTS_FILE}" ]
then
  REQUIREMENTS_FILE=$(realpath "${REQUIREMENTS_FILE}")
else
  unset REQUIREMENTS_FILE
fi

if [ -z "${OUTPUT_DIR}" ]
then
  OUTPUT_DIR="${PROJECT_ROOT}/dist"
fi
mkdir -p ${OUTPUT_DIR}
if [ ! -d "${OUTPUT_DIR}" ]
then
  echo "can't create output dir '${OUTPUT_DIR}"
  exit 1
fi
OUTPUT_DIR=$(realpath "${OUTPUT_DIR}")

if [ -z ${SPEC_FILE} ]
then
  SPEC_FILE="${THIS_DIR}/onefile.spec"
fi
if [ ! -f "${SPEC_FILE}" ]
then
  echo "spec file '${SPEC_FILE} does not exist"
  exit 1
fi
SPEC_FILE=$(realpath "$SPEC_FILE")

if [ -z ${PYTHON_TYPE} ]
then
  PYTHON_TYPE="current-env"
fi

if [ -z "${PYTHON_VERSION}" ]
then
  PYTHON_VERSION="${DEFAULT_PYTHON_VERSION}"
fi



echo "project root: ${PROJECT_ROOT}"
echo "requirements file: ${REQUIREMENTS_FILE}"
echo "spec file: ${SPEC_FILE}"
echo "output dir: ${OUTPUT_DIR}"
echo "build dir: ${BUILD_DIR}"
echo "python version: ${PYTHON_VERSION}"
echo "pyinstaller version: ${PYINSTALLER_VERSION}"

echo
echo "starting build..."
echo

set -e
#set -x

if [ ! -f "${PROJECT_ROOT}/setup.py" ];
then
  echo "Can't continue, no 'setup.py' file in project root: ${PROJECT_ROOT}"
  exit 3
fi

main "${PYTHON_TYPE}" "${PROJECT_ROOT}" "${BUILD_DIR}" "${PYTHON_VERSION}" "${PYINSTALLER_VERSION}" "${REQUIREMENTS_FILE}" "${OUTPUT_DIR}" "${SPEC_FILE}"

set +e
#set +x

echo
echo "build finished"
echo
