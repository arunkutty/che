#!/bin/bash
# Copyright (c) 2012-2016 Codenvy, S.A.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Tyler Jewell - Initial Implementation
#

init_global_variables() {
  DEFAULT_CHE_PRODUCT_NAME="ECLIPSE CHE"
  DEFAULT_CHE_LAUNCHER_IMAGE_NAME="codenvy/che-launcher"
  DEFAULT_CHE_SERVER_IMAGE_NAME="codenvy/che-server"
  DEFAULT_CHE_DIR_IMAGE_NAME="codenvy/che-dir"
  DEFAULT_CHE_MOUNT_IMAGE_NAME="codenvy/che-mount"
  DEFAULT_CHE_ACTION_IMAGE_NAME="codenvy/che-action"
  DEFAULT_CHE_TEST_IMAGE_NAME="codenvy/che-test"
  DEFAULT_CHE_DEV_IMAGE_NAME="codenvy/che-dev"
  DEFAULT_CHE_SERVER_CONTAINER_NAME="che-server"
  DEFAULT_CHE_VERSION="latest"
  DEFAULT_CHE_UTILITY_VERSION="nightly"
  DEFAULT_CHE_CLI_ACTION="help"
  DEFAULT_IS_INTERACTIVE="true"
  DEFAULT_IS_PSEUDO_TTY="true"
  DEFAULT_CHE_DATA_FOLDER="/home/user/che"

  CHE_PRODUCT_NAME=${CHE_PRODUCT_NAME:-${DEFAULT_CHE_PRODUCT_NAME}}
  CHE_LAUNCHER_IMAGE_NAME=${CHE_LAUNCHER_IMAGE_NAME:-${DEFAULT_CHE_LAUNCHER_IMAGE_NAME}}
  CHE_SERVER_IMAGE_NAME=${CHE_SERVER_IMAGE_NAME:-${DEFAULT_CHE_SERVER_IMAGE_NAME}}
  CHE_DIR_IMAGE_NAME=${CHE_DIR_IMAGE_NAME:-${DEFAULT_CHE_DIR_IMAGE_NAME}}
  CHE_MOUNT_IMAGE_NAME=${CHE_MOUNT_IMAGE_NAME:-${DEFAULT_CHE_MOUNT_IMAGE_NAME}}
  CHE_ACTION_IMAGE_NAME=${CHE_ACTION_IMAGE_NAME:-${DEFAULT_CHE_ACTION_IMAGE_NAME}}
  CHE_TEST_IMAGE_NAME=${CHE_TEST_IMAGE_NAME:-${DEFAULT_CHE_TEST_IMAGE_NAME}}
  CHE_DEV_IMAGE_NAME=${CHE_DEV_IMAGE_NAME:-${DEFAULT_CHE_DEV_IMAGE_NAME}}
  CHE_SERVER_CONTAINER_NAME=${CHE_SERVER_CONTAINER_NAME:-${DEFAULT_CHE_SERVER_CONTAINER_NAME}}
  CHE_VERSION=${CHE_VERSION:-${DEFAULT_CHE_VERSION}}
  CHE_UTILITY_VERSION=${CHE_UTILITY_VERSION:-${DEFAULT_CHE_UTILITY_VERSION}}
  CHE_CLI_ACTION=${CHE_CLI_ACTION:-${DEFAULT_CHE_CLI_ACTION}}
  CHE_IS_INTERACTIVE=${CHE_IS_INTERACTIVE:-${DEFAULT_IS_INTERACTIVE}}
  CHE_IS_PSEUDO_TTY=${CHE_IS_PSEUDO_TTY:-${DEFAULT_IS_PSEUDO_TTY}}
  CHE_DATA_FOLDER=${CHE_DATA_FOLDER:-${DEFAULT_CHE_DATA_FOLDER}}

  GLOBAL_NAME_MAP=$(docker info | grep "Name:" | cut -d" " -f2)
  GLOBAL_HOST_ARCH=$(docker version --format {{.Client}} | cut -d" " -f5)
  GLOBAL_UNAME=$(docker run --rm alpine sh -c "uname -r")
  GLOBAL_GET_DOCKER_HOST_IP=$(get_docker_host_ip)

  if is_boot2docker && has_docker_for_windows_client; then
    if [[ "${CHE_DATA_FOLDER,,}" != *"${USERPROFILE,,}"* ]]; then
      CHE_DATA_FOLDER=$(get_mount_path "${USERPROFILE}/.${CHE_MINI_PRODUCT_NAME}/")
      warning "Boot2docker for Windows - CHE_DATA_FOLDER set to $CHE_DATA_FOLDER"   
    fi
  fi

  USAGE="
Usage: ${CHE_MINI_PRODUCT_NAME} [COMMAND]
    start                              Starts ${CHE_MINI_PRODUCT_NAME} server
    stop                               Stops ${CHE_MINI_PRODUCT_NAME} server
    restart                            Restart ${CHE_MINI_PRODUCT_NAME} server
    update [--force]                   Installs version, respecting CHE_VERSION & CHE_UTILITY_VERSION
    profile add <name>                 Add a profile to ~/.${CHE_MINI_PRODUCT_NAME}/ 
    profile set <name>                 Set this profile as the default for ${CHE_MINI_PRODUCT_NAME} CLI
    profile unset                      Removes the default profile - leaves it unset
    profile rm <name>                  Remove this profile from ~/.${CHE_MINI_PRODUCT_NAME}/
    profile update <name>              Update profile in ~/.${CHE_MINI_PRODUCT_NAME}/
    profile info <name>                Print the profile configuration
    profile list                       List available profiles
    mount [<ws-ssh-port>]              Synchronize workspace with current working directory
    dir init                           Initialize directory with ${CHE_MINI_PRODUCT_NAME} configuration
    dir up                             Create workspace from source in current directory
    dir down                           Stop workspace running in current directory
    dir status                         Display status of ${CHE_MINI_PRODUCT_NAME} in current directory
    dir ssh                            Make SSH connection into workspace mapped to current directory
    action <action-name> [--help]      Start action on ${CHE_MINI_PRODUCT_NAME} instance
    compile <mvn-command>              SDK - Builds Che source code or modules
    test <test-name> [--help]          Start test on ${CHE_MINI_PRODUCT_NAME} instance
    info [ --all                       Run all debugging tests
           --server                    Run ${CHE_MINI_PRODUCT_NAME} launcher and server debugging tests
           --networking                Test connectivity between ${CHE_MINI_PRODUCT_NAME} sub-systems
           --cli                       Print CLI (this program) debugging info
           --create [<url>]            Test creating a workspace and project in ${CHE_MINI_PRODUCT_NAME}
                    [<user>] 
                    [<pass>] ]

Variables:
    CHE_VERSION                        Version of Che to run
    CHE_PORT                           External port of Che server
    CHE_HOST_IP                        IP address Che server binds to - must set for external users
    CHE_DATA_FOLDER                    Where workspaces and Che prefs are stored
    CHE_HOSTNAME                       External hostname of Che server
    CHE_CONF_FOLDER                    Folder for custom che.properties file
    CHE_RESTART_POLICY                 Che server Docker restart policy if container exited
    CHE_USER                           User ID of the Che server inside its container
    CHE_LOCAL_BINARY                   Path to a Che assembly to use instead of binary in container
    CHE_LOG_LEVEL                      Logging level for Che server - either debug or info
    CHE_EXTRA_VOLUME_MOUNT             Folders to mount from host into Che workspaces
    CHE_PROPERTY_<>                    One time use properties passed to Che - see docs
    CHE_UTILITY_VERSION                Version of Che launcher, mount, dev, action to run
    CHE_CLI_VERSION                    Version of CLI to run
    CHE_PRODUCT_NAME                   Pretty name used by CLI in INFO statements
    CHE_MINI_PRODUCT_NAME              Pretty short name used by CLI in INFO statements
    CHE_LAUNCHER_IMAGE_NAME            Docker image for the Che launcher
    CHE_SERVER_IMAGE_NAME              Docker image for the Che server
    CHE_DIR_IMAGE_NAME                 Docker image for Chedir
    CHE_MOUNT_IMAGE_NAME               Docker image used for local IDE mount and sync
    CHE_ACTION_IMAGE_NAME              Docker image used for Che actions
    CHE_DEV_IMAGE_NAME                 Docker image used to compile and package Che source code
    CHE_SERVER_CONTAINER_NAME          Pretty container name given for the Che server container
    CHE_IS_INTERACTIVE                 Passes -i into Docker run
    CHE_IS_PSEUDO_TTY                  Passes -t into Docker run
    CHE_DEBUG_SERVER                   Launches Che server with JPDA activated
    CHE_DEBUG_SERVER_PORT              Port JPDA binds itself to
"
}

usage () {
  debug $FUNCNAME
  printf "%s" "${USAGE}"
}

parse_command_line () {
  debug $FUNCNAME
  if [ $# -eq 0 ]; then 
    CHE_CLI_ACTION="help"
  else
    case $1 in
      start|stop|restart|update|info|profile|action|dir|mount|compile|test|help|-h|--help)
        CHE_CLI_ACTION=$1
      ;;
      *)
        # unknown option
        error "You passed an unknown command line option."
      ;;
    esac
  fi
}

execute_cli() {
  case ${CHE_CLI_ACTION} in
    start|stop|restart)
      shift 
      load_profile
      execute_che_launcher "$@"
    ;;
    profile)
      execute_profile "$@"
    ;;
    dir)
      # remove "dir" arg by shifting it
      shift
      load_profile
      execute_che_dir "$@"
    ;;
    action)
      # remove "action" arg by shifting it
      shift
      load_profile
      execute_che_action "$@"
    ;;
    update)
      shift
      load_profile
      update_che_cli
      update_che_image "$@" ${CHE_SERVER_IMAGE_NAME} ${CHE_VERSION}
      update_che_image "$@" ${CHE_LAUNCHER_IMAGE_NAME} ${CHE_UTILITY_VERSION}
      update_che_image "$@" ${CHE_MOUNT_IMAGE_NAME} ${CHE_UTILITY_VERSION}
      update_che_image "$@" ${CHE_DIR_IMAGE_NAME} ${CHE_UTILITY_VERSION}
      update_che_image "$@" ${CHE_ACTION_IMAGE_NAME} ${CHE_UTILITY_VERSION}
      update_che_image "$@" ${CHE_TEST_IMAGE_NAME} ${CHE_UTILITY_VERSION}
      update_che_image "$@" ${CHE_DEV_IMAGE_NAME} ${CHE_UTILITY_VERSION}
    ;;
    mount)
      shift
      load_profile
      execute_che_mount "$@"
    ;;
    compile)
      # remove "compile" arg by shifting it
      shift
      load_profile
      execute_che_compile "$@"
    ;;
    test)
      # remove "test" arg by shifting it
      shift
      load_profile
      execute_che_test "$@"
    ;;
    info)
      load_profile
      execute_che_info "$@"
    ;;
    help)
      usage
    ;;
  esac
}

docker_exec() {
  debug $FUNCNAME
  if has_docker_for_windows_client; then
    MSYS_NO_PATHCONV=1 docker.exe "$@"
  else
    "$(which docker)" "$@"
  fi
}

docker_run() {
  debug $FUNCNAME
  docker_exec run --rm -v /var/run/docker.sock:/var/run/docker.sock "$@"
}

docker_run_with_env_file() {
  debug $FUNCNAME
  get_list_of_che_system_environment_variables
  
  # Silly issue - docker run --env-file does not accept path to file - must be in same dir
  cd ~/."${CHE_MINI_PRODUCT_NAME}"
  docker_run --env-file tmpgibberish "$@"
  rm -rf ~/."${CHE_MINI_PRODUCT_NAME}"/tmpgibberish > /dev/null
}

docker_run_with_pseudo_tty() {
  debug $FUNCNAME
  if has_pseudo_tty; then
    docker_run_with_env_file -t "$@"
  else
    docker_run_with_env_file "$@"
  fi
}

docker_run_with_interactive() {
  debug $FUNCNAME
  if has_interactive; then
    docker_run_with_pseudo_tty -i "$@"
  else
    docker_run_with_pseudo_tty "$@"
  fi
}

docker_run_with_che_properties() {
  debug $FUNCNAME
  if [ ! -z ${CHE_CONF_FOLDER+x} ]; then

    # Configuration directory set by user - this has precedence.
    docker_run_with_interactive -e "CHE_CONF_FOLDER=${CHE_CONF_FOLDER}" "$@"
  else 
    if has_che_properties; then
      # No user configuration directory, but CHE_PROPERTY_ values set
      generate_temporary_che_properties_file
      docker_run_with_interactive -e "CHE_CONF_FOLDER=$(get_mount_path ~/.${CHE_MINI_PRODUCT_NAME}/conf)" "$@"
      rm -rf ~/."${CHE_MINI_PRODUCT_NAME}"/conf/che.properties > /dev/null
    else
      docker_run_with_interactive "$@"
    fi
  fi
}

has_interactive() {
  debug $FUNCNAME
  if [ "${CHE_IS_INTERACTIVE}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

has_pseudo_tty() {
  debug $FUNCNAME
  if [ "${CHE_IS_PSEUDO_TTY}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

get_docker_host_ip() {
  debug $FUNCNAME
  case $(get_docker_install_type) in
   boot2docker)
     NETWORK_IF="eth1"
   ;;
   native)
     NETWORK_IF="docker0"
   ;;
   *)
     NETWORK_IF="eth0"
   ;;
  esac
  
  docker run --rm --net host \
            alpine sh -c \
            "ip a show ${NETWORK_IF}" | \
            grep 'inet ' | \
            cut -d/ -f1 | \
            awk '{ print $2}'
}

get_docker_install_type() {
  debug $FUNCNAME
  if is_boot2docker; then
    echo "boot2docker"
  elif is_docker_for_windows; then
    echo "docker4windows"
  elif is_docker_for_mac; then
    echo "docker4mac"
  else
    echo "native"
  fi
}

is_boot2docker() {
  debug $FUNCNAME
  if echo "$GLOBAL_UNAME" | grep -q "boot2docker"; then
    return 0
  else
    return 1
  fi
}

is_docker_for_mac() {
  debug $FUNCNAME
  if is_moby_vm && ! has_docker_for_windows_client; then
    return 0
  else
    return 1
  fi
}

is_docker_for_windows() {
  debug $FUNCNAME
  if is_moby_vm && has_docker_for_windows_client; then
    return 0
  else
    return 1
  fi
}

is_native() {
  debug $FUNCNAME
  if [ $(get_docker_install_type) = "native" ]; then
    return 0
  else
    return 1
  fi
}

is_moby_vm() {
  debug $FUNCNAME
  if echo "$GLOBAL_NAME_MAP" | grep -q "moby"; then
    return 0
  else
    return 1
  fi
}

has_docker_for_windows_client(){
  debug $FUNCNAME
  if [ "${GLOBAL_HOST_ARCH}" = "windows" ]; then
    return 0
  else
    return 1
  fi
}

get_full_path() {
  debug $FUNCNAME
  # "/some/path" => /some/path
  #OUTPUT_PATH=${1//\"}

  # create full directory path
  echo "$(cd "$(dirname "${1}")"; pwd)/$(basename "$1")"
}

convert_windows_to_posix() {
  debug $FUNCNAME
  echo "/"$(echo "$1" | sed 's/\\/\//g' | sed 's/://')
}

get_clean_path() {
  debug $FUNCNAME
  INPUT_PATH=$1
  # \some\path => /some/path
  OUTPUT_PATH=$(echo ${INPUT_PATH} | tr '\\' '/')
  # /somepath/ => /somepath
  OUTPUT_PATH=${OUTPUT_PATH%/}
  # /some//path => /some/path
  OUTPUT_PATH=$(echo ${OUTPUT_PATH} | tr -s '/')
  # "/some/path" => /some/path
  OUTPUT_PATH=${OUTPUT_PATH//\"}
  echo ${OUTPUT_PATH}
}

get_mount_path() {
  debug $FUNCNAME
  FULL_PATH=$(get_full_path "${1}")

  POSIX_PATH=$(convert_windows_to_posix "${FULL_PATH}")

  CLEAN_PATH=$(get_clean_path "${POSIX_PATH}")
  echo $CLEAN_PATH
}

has_docker_for_windows_ip() {
  debug $FUNCNAME
  if [ "${GLOBAL_GET_DOCKER_HOST_IP}" = "10.0.75.2" ]; then
    return 0
  else
    return 1
  fi
}

get_che_hostname() {
  debug $FUNCNAME
  INSTALL_TYPE=$(get_docker_install_type)
  if [ "${INSTALL_TYPE}" = "boot2docker" ]; then
    echo $GLOBAL_GET_DOCKER_HOST_IP
  else
    echo "localhost"
  fi
}

has_che_env_variables() {
  debug $FUNCNAME
  PROPERTIES=$(env | grep CHE_)

  if [ "$PROPERTIES" = "" ]; then
    return 1
  else 
    return 0
  fi 
}

get_list_of_che_system_environment_variables() {
  debug $FUNCNAME

  # See: http://stackoverflow.com/questions/4128235/what-is-the-exact-meaning-of-ifs-n
  IFS=$'\n'
  
  TMP_DIR=~/."${CHE_MINI_PRODUCT_NAME}"
  TMP_FILE="${TMP_DIR}"/tmpgibberish

  test -d "${TMP_DIR}" || mkdir -p "${TMP_DIR}"
  touch "${TMP_FILE}"

  if has_default_profile; then
    cat "${TMP_DIR}"/profiles/"${CHE_PROFILE}" | sed 's/\"//g' >> "${TMP_FILE}"
  else

    # Grab these values to send to other utilities - they need to know the values  
    echo "CHE_SERVER_CONTAINER_NAME=${CHE_SERVER_CONTAINER_NAME}" >> "${TMP_FILE}"
    echo "CHE_SERVER_IMAGE_NAME=${CHE_SERVER_IMAGE_NAME}" >> "${TMP_FILE}"
    echo "CHE_PRODUCT_NAME=${CHE_PRODUCT_NAME}" >> "${TMP_FILE}"
    echo "CHE_MINI_PRODUCT_NAME=${CHE_MINI_PRODUCT_NAME}" >> "${TMP_FILE}"
    echo "CHE_VERSION=${CHE_VERSION}" >> "${TMP_FILE}"
    echo "CHE_CLI_INFO=${CHE_CLI_INFO}" >> "${TMP_FILE}"
    echo "CHE_CLI_DEBUG=${CHE_CLI_DEBUG}" >> "${TMP_FILE}"
    echo "CHE_DATA_FOLDER=${CHE_DATA_FOLDER}" >> "${TMP_FILE}"

    CHE_VARIABLES=$(env | grep CHE_)

    if [ ! -z ${CHE_VARIABLES+x} ]; then
      env | grep CHE_ >> "${TMP_FILE}"
    fi

    # Add in known proxy variables
    if [ ! -z ${http_proxy+x} ]; then
      echo "http_proxy=${http_proxy}" >> "${TMP_FILE}"
    fi

    if [ ! -z ${https_proxy+x} ]; then
      echo "https_proxy=${https_proxy}" >> "${TMP_FILE}"
    fi

    if [ ! -z ${no_proxy+x} ]; then
      echo "no_proxy=${no_proxy}" >> "${TMP_FILE}"
    fi
  fi
}

check_current_image_and_update_if_not_found() {
  debug $FUNCNAME

  CURRENT_IMAGE=$(docker images -q "$1":"$2")

  if [ "${CURRENT_IMAGE}" == "" ]; then
    update_che_image $1 $2
  fi
}

has_che_properties() {
  debug $FUNCNAME
  PROPERTIES=$(env | grep CHE_PROPERTY_)

  if [ "$PROPERTIES" = "" ]; then
    return 1
  else 
    return 0
  fi 
}

generate_temporary_che_properties_file() {
  debug $FUNCNAME
  if has_che_properties; then
    test -d ~/."${CHE_MINI_PRODUCT_NAME}"/conf || mkdir -p ~/."${CHE_MINI_PRODUCT_NAME}"/conf
    touch ~/."${CHE_MINI_PRODUCT_NAME}"/conf/che.properties

    # Get list of properties
    PROPERTIES_ARRAY=($(env | grep CHE_PROPERTY_))
    for PROPERTY in "${PROPERTIES_ARRAY[@]}"
    do
      # CHE_PROPERTY_NAME=value ==> NAME=value
      PROPERTY_WITHOUT_PREFIX=${PROPERTY#CHE_PROPERTY_}

      # NAME=value ==> separate name / value into different variables
      PROPERTY_NAME=$(echo $PROPERTY_WITHOUT_PREFIX | cut -f1 -d=)
      PROPERTY_VALUE=$(echo $PROPERTY_WITHOUT_PREFIX | cut -f2 -d=)
     
      # Replace "_" in names to periods
      CONVERTED_PROPERTY_NAME=$(echo "$PROPERTY_NAME" | tr _ .)

      # Replace ".." in names to "_"
      SUPER_CONVERTED_PROPERTY_NAME="${CONVERTED_PROPERTY_NAME//../_}"

      echo "$SUPER_CONVERTED_PROPERTY_NAME=$PROPERTY_VALUE" >> ~/."${CHE_MINI_PRODUCT_NAME}"/conf/che.properties
    done
  fi
}

contains() {
  string="$1"
  substring="$2"
  if test "${string#*$substring}" != "$string"
  then
    return 0    # $substring is in $string
  else
    return 1    # $substring is not in $string
  fi
}

get_container_ssh() {
  CURRENT_CHE_DEBUG=$(docker inspect --format='{{.NetworkSettings.Ports}}' ${1})
  IFS=$' '
  for SINGLE_BIND in $CURRENT_CHE_DEBUG; do
    case $SINGLE_BIND in
      *22/tcp:*)
        echo $SINGLE_BIND | cut -f2 -d":"
        return
      ;;
      *)
      ;;
    esac
  done
  echo "<nil>"
}

has_ssh () {
  if $(contains $(get_container_ssh $1) "<nil>"); then
    return 1
  else
    return 0
  fi
}

has_default_profile() {
  debug $FUNCNAME
  if [ -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile ]; then
    return 0
  else 
    return 1
  fi 
}

get_default_profile() {
  debug $FUNCNAME
  if [ has_default_profile ]; then
    source ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile
    echo "${CHE_PROFILE}"
  else
    echo ""
  fi
}

load_profile() {
  debug $FUNCNAME
  if has_default_profile; then

    source ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile

    if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${CHE_PROFILE}" ]; then
      error ""
      error "${CHE_MINI_PRODUCT_NAME} CLI profile set in ~/.${CHE_MINI_PRODUCT_NAME}/profiles/.profile to '${CHE_PROFILE}' but ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${CHE_PROFILE} does not exist."
      error ""
      return
    fi

    source ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${CHE_PROFILE}"
    info "${CHE_PRODUCT_NAME}: Loaded profile ${CHE_PROFILE}"
  fi
}

###########################################################################
### END HELPER FUNCTIONS
###
### START CLI COMMANDS
###########################################################################

execute_che_launcher() {
  debug $FUNCNAME

  if [ $# -gt 0 ]; then
    error "${CHE_MINI_PRODUCT_NAME} start/stop/start: You passed unknown options."
    return
  fi

  check_current_image_and_update_if_not_found ${CHE_LAUNCHER_IMAGE_NAME} ${CHE_UTILITY_VERSION}
  docker_run_with_che_properties "${CHE_LAUNCHER_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" "${CHE_CLI_ACTION}" || true
}

execute_profile(){
  debug $FUNCNAME

  if [ ! $# -ge 2 ]; then 
    error "${CHE_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
    return
  fi

  case ${2} in
    add|rm|set|info|update)
    if [ ! $# -eq 3 ]; then 
      error "${CHE_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
      return
    fi
    ;;
    unset|list)
    if [ ! $# -eq 2 ]; then 
      error "${CHE_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
      return
    fi
    ;;
  esac

  case ${2} in
    add)
      if [ -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3} already exists. Nothing to do. Exiting."
        return
      fi

      PROFILE_DIR=~/."${CHE_MINI_PRODUCT_NAME}"/profiles
      PROFILE_FILE="${PROFILE_DIR}"/"${3}"
      test -d "${PROFILE_DIR}" || mkdir -p "${PROFILE_DIR}"
      touch "${PROFILE_FILE}"

      echo "CHE_PRODUCT_NAME=\"""${CHE_PRODUCT_NAME}""\"" >> "${PROFILE_FILE}"
      echo "CHE_MINI_PRODUCT_NAME=\"""${CHE_MINI_PRODUCT_NAME}""\"" >> "${PROFILE_FILE}"
      echo "CHE_LAUNCHER_IMAGE_NAME=$CHE_LAUNCHER_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "CHE_SERVER_IMAGE_NAME=$CHE_SERVER_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "CHE_DIR_IMAGE_NAME=$CHE_DIR_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "CHE_MOUNT_IMAGE_NAME=$CHE_MOUNT_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "CHE_TEST_IMAGE_NAME=$CHE_TEST_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "CHE_SERVER_CONTAINER_NAME=$CHE_SERVER_CONTAINER_NAME" >> "${PROFILE_FILE}"
      echo "CHE_VERSION=$CHE_VERSION" >> "${PROFILE_FILE}"

      # Add all other variables to the profile
      env | grep CHE_ >> "${PROFILE_FILE}" || true

      # Remove duplicates, if any
      cat "${PROFILE_FILE}" | sort | uniq > "${PROFILE_DIR}"/tmp
      mv -f "${PROFILE_DIR}"/tmp "${PROFILE_FILE}"


      info "Added new ${CHE_MINI_PRODUCT_NAME} CLI profile ${PROFILE_FILE}."
    ;;
    update)
      if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to update. Exiting."
        return
      fi

      execute_profile profile rm "${3}"
      execute_profile profile add "${3}"
    ;;
    rm)
      if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to do. Exiting."
        return
      fi

      rm ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" > /dev/null

      info "Removed ${CHE_MINI_PRODUCT_NAME} CLI profile ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3}."
    ;;
    info)
      if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to do. Exiting."
        return
      fi
 
      while IFS= read line
      do
        # display $line or do somthing with $line
        info "$line"
      done <~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}"
    ;;
    set)
      if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${CHE_MINI_PRODUCT_NAME}/${3} does not exist. Nothing to do. Exiting."
        return
      fi
      
      echo "CHE_PROFILE=${3}" > ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile

      info "Set active ${CHE_MINI_PRODUCT_NAME} CLI profile to ~/.${CHE_MINI_PRODUCT_NAME}/profiles/${3}."
    ;;
    unset)
      if [ ! -f ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile ]; then
        error "Default profile not set. Nothing to do. Exiting."
        return
      fi
      
      rm -rf ~/."${CHE_MINI_PRODUCT_NAME}"/profiles/.profile

      info "Unset the default ${CHE_MINI_PRODUCT_NAME} CLI profile. No profile currently set."
    ;;
    list)
      if [ -d ~/."${CHE_MINI_PRODUCT_NAME}"/profiles ]; then
        info "Available ${CHE_MINI_PRODUCT_NAME} CLI profiles:"
        ls ~/."${CHE_MINI_PRODUCT_NAME}"/profiles
      else
        info "No ${CHE_MINI_PRODUCT_NAME} CLI profiles currently set."
      fi

      if has_default_profile; then
        info "Default profile set to:"
        get_default_profile
      else
        info "Default profile currently unset."
      fi
    ;;
  esac
}

execute_che_dir() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${CHE_DIR_IMAGE_NAME} ${CHE_UTILITY_VERSION}
  CURRENT_DIRECTORY=$(get_mount_path "${PWD}")
  docker_run_with_che_properties -v "$CURRENT_DIRECTORY":"$CURRENT_DIRECTORY" "${CHE_DIR_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" "${CURRENT_DIRECTORY}" "$@"
}

execute_che_action() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${CHE_ACTION_IMAGE_NAME} ${CHE_UTILITY_VERSION}
  docker_run_with_che_properties "${CHE_ACTION_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" "$@"
}

update_che_image() {
  debug $FUNCNAME
  if [ "${1}" == "--force" ]; then
    shift
    info "${CHE_PRODUCT_NAME}: Removing image $1:$2"
    docker rmi -f $1:$2 > /dev/null
  fi

  info "${CHE_PRODUCT_NAME}: Pulling image $1:$2"
  docker pull $1:$2
  echo ""
}

execute_che_mount() {
  debug $FUNCNAME

  # Determine the mount path to do the mount
  info "${CHE_MINI_PRODUCT_NAME} mount: Setting local mount path to ${PWD}"
  MOUNT_PATH=$(get_mount_path "${PWD}")
  HOME_PATH=$(get_mount_path "${HOME}")

  # If extra parameter provided, then this is the port to connect to
  if [ $# -eq 1 ]; then
    info "${CHE_MINI_PRODUCT_NAME} mount: Connecting to remote workspace on port ${1}"
    WS_PORT=${1}

  # Port not provided, let's do a simple discovery of running workspaces
  else 
    info "${CHE_MINI_PRODUCT_NAME} mount: Searching for running workspaces with open SSH port..."

    CURRENT_WS_INSTANCES=$(docker ps -aq --filter "name=workspace")
    CURRENT_WS_COUNT=$(echo $CURRENT_WS_INSTANCES | wc -w)
    
    # No running workspaces
    if [ $CURRENT_WS_COUNT -eq 0 ]; then
      error "${CHE_MINI_PRODUCT_NAME} mount: We could not find any running workspaces"
      return

    # Exactly 1 running workspace
    elif [ $CURRENT_WS_COUNT -eq 1 ]; then

      if has_ssh ${CURRENT_WS_INSTANCES}; then
        RUNNING_WS_PORT=$(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${CURRENT_WS_INSTANCES})
        info "${CHE_MINI_PRODUCT_NAME} mount: Connecting to remote workspace on port $RUNNING_WS_PORT"
        WS_PORT=$RUNNING_WS_PORT
      else
        error "${CHE_MINI_PRODUCT_NAME} mount: We found 1 running workspace, but it does not have an SSH agent"
        return
      fi

    # 2+ running workspace
    else 
      info "${CHE_MINI_PRODUCT_NAME} mount: Re-run with 'che mount <ssh-port>'"
      IFS=$'\n'

      echo "WS CONTAINER ID    HAS SSH?    SSH PORT"
      for CHE_WS_CONTAINER_ID in $CURRENT_WS_INSTANCES; do
        CURRENT_WS_PORT=""
        if has_ssh ${CHE_WS_CONTAINER_ID}; then 
          CURRENT_WS_PORT=$(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${CHE_WS_CONTAINER_ID})
        fi
        echo "$CHE_WS_CONTAINER_ID       $(has_ssh ${CHE_WS_CONTAINER_ID} && echo "y" || echo "n")           $CURRENT_WS_PORT"
      done
      return
    fi
  fi
  
  if is_native; then
    docker_run_with_che_properties --cap-add SYS_ADMIN \
                                   --device /dev/fuse \
                                   -v ${HOME}/.ssh:${HOME}/.ssh \
                                   -v ${HOME}/.unison:${HOME}/.unison \
                                   -v /etc/group:/etc/group:ro \
                                   -v /etc/passwd:/etc/passwd:ro \
                                   -u $(id -u ${USER}) \
                                   -v "${MOUNT_PATH}":/mnthost \
                                   "${CHE_MOUNT_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" \
                                        "${GLOBAL_GET_DOCKER_HOST_IP}" $WS_PORT
    
  else
    docker_run_with_che_properties --cap-add SYS_ADMIN \
                                   --device /dev/fuse \
                                   -v "${HOME_PATH}"/.ssh:/root/.ssh \
                                   -v "${MOUNT_PATH}":/mnthost \
                                   "${CHE_MOUNT_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" \
                                        "${GLOBAL_GET_DOCKER_HOST_IP}" $WS_PORT
  fi

}

execute_che_compile() {
  debug $FUNCNAME
  if [ $# -eq 0 ]; then 
    error "${CHE_MINI_PRODUCT_NAME} compile: Missing argument - pass compilation command as paramters."
    return
  fi

  check_current_image_and_update_if_not_found ${CHE_DEV_IMAGE_NAME} ${CHE_UTILITY_VERSION}
  CURRENT_DIRECTORY=$(get_mount_path "${PWD}")
  docker_run_with_che_properties -v "$CURRENT_DIRECTORY":/home/user/che-build \
                                 -v "$(get_mount_path ~/.m2):/home/user/.m2" \
                                 -w /home/user/che-build \
                                 "${CHE_DEV_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" "$@"
}

execute_che_test() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${CHE_TEST_IMAGE_NAME} ${CHE_UTILITY_VERSION}
  docker_run_with_che_properties "${CHE_TEST_IMAGE_NAME}":"${CHE_UTILITY_VERSION}" "$@"
}

execute_che_info() {
  debug $FUNCNAME
  if [ $# -eq 1 ]; then
    TESTS="--server"
  else
    TESTS=$2
  fi
  
  case $TESTS in
    --all|-all)
      print_che_cli_debug
      execute_che_launcher
      run_connectivity_tests
      execute_che_test post-flight-check "$@"
    ;;
    --cli|-cli)
      print_che_cli_debug
    ;;
    --networking|-networking)
      run_connectivity_tests
    ;;
    --server|-server)
      print_che_cli_debug
      execute_che_launcher
    ;;
    --create|-create)
      execute_che_test "$@"
    ;;
    *)
      info "Unknown info flag passed: $2. Exiting."
    ;;
  esac
}

print_che_cli_debug() {
  debug $FUNCNAME
  info "---------------------------------------"
  info "-------------   CLI INFO   ------------"
  info "---------------------------------------"
  info ""
  info "---------  PLATFORM INFO  -------------"
  info "CLI DEFAULT PROFILE       = $(has_default_profile && echo $(get_default_profile) || echo "not set")"
  info "CHE_VERSION               = ${CHE_VERSION}"
  info "CHE_CLI_VERSION           = ${CHE_CLI_VERSION}"
  info "CHE_UTILITY_VERSION       = ${CHE_UTILITY_VERSION}"
  info "DOCKER_INSTALL_TYPE       = $(get_docker_install_type)"
  info "DOCKER_HOST_IP            = ${GLOBAL_GET_DOCKER_HOST_IP}"
  info "IS_NATIVE                 = $(is_native && echo "YES" || echo "NO")"
  info "IS_WINDOWS                = $(has_docker_for_windows_client && echo "YES" || echo "NO")"
  info "IS_DOCKER_FOR_WINDOWS     = $(is_docker_for_windows && echo "YES" || echo "NO")"
  info "IS_DOCKER_FOR_MAC         = $(is_docker_for_mac && echo "YES" || echo "NO")"
  info "IS_BOOT2DOCKER            = $(is_boot2docker && echo "YES" || echo "NO")"
  info "HAS_DOCKER_FOR_WINDOWS_IP = $(has_docker_for_windows_ip && echo "YES" || echo "NO")"
  info "IS_MOBY_VM                = $(is_moby_vm && echo "YES" || echo "NO")"
  info "HAS_CHE_ENV_VARIABLES     = $(has_che_env_variables && echo "YES" || echo "NO")"
  info "HAS_TEMP_CHE_PROPERTIES   = $(has_che_properties && echo "YES" || echo "NO")"
  info "IS_INTERACTIVE            = $(has_interactive && echo "YES" || echo "NO")"
  info "IS_PSEUDO_TTY             = $(has_pseudo_tty && echo "YES" || echo "NO")"
  info ""
}

run_connectivity_tests() {
  debug $FUNCNAME
  info ""
  info "---------------------------------------"
  info "--------   CONNECTIVITY TEST   --------"
  info "---------------------------------------"
  # Start a fake workspace agent
  docker_exec run -d -p 12345:80 --name fakeagent alpine httpd -f -p 80 -h /etc/ > /dev/null

  AGENT_INTERNAL_IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' fakeagent)
  AGENT_INTERNAL_PORT=80
  AGENT_EXTERNAL_IP=$GLOBAL_GET_DOCKER_HOST_IP
  AGENT_EXTERNAL_PORT=12345


  ### TEST 1: Simulate browser ==> workspace agent HTTP connectivity
  HTTP_CODE=$(curl -I $(get_che_hostname):${AGENT_EXTERNAL_PORT}/alpine-release \
                          -s -o /dev/null --connect-timeout 5 \
                          --write-out "%{http_code}") || echo "28" > /dev/null

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Browser             => Workspace Agent (Hostname)   : Connection succeeded"
  else
      info "Browser             => Workspace Agent (Hostname)   : Connection failed"
  fi

  ### TEST 1a: Simulate browser ==> workspace agent HTTP connectivity
  HTTP_CODE=$(curl -I ${AGENT_EXTERNAL_IP}:${AGENT_EXTERNAL_PORT}/alpine-release \
                          -s -o /dev/null --connect-timeout 5 \
                          --write-out "%{http_code}") || echo "28" > /dev/null

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Browser             => Workspace Agent (External IP): Connection succeeded"
  else
      info "Browser             => Workspace Agent (External IP): Connection failed"
  fi

  ### TEST 2: Simulate Che server ==> workspace agent (external IP) connectivity 
  export HTTP_CODE=$(docker run --rm --name fakeserver \
                                --entrypoint=curl \
                                ${CHE_SERVER_IMAGE_NAME}:${CHE_VERSION} \
                                  -I ${AGENT_EXTERNAL_IP}:${AGENT_EXTERNAL_PORT}/alpine-release \
                                  -s -o /dev/null \
                                  --write-out "%{http_code}")
  
  if [ "${HTTP_CODE}" = "200" ]; then
      info "Che Server          => Workspace Agent (External IP): Connection succeeded"
  else
      info "Che Server          => Workspace Agent (External IP): Connection failed"
  fi

  ### TEST 3: Simulate Che server ==> workspace agent (internal IP) connectivity 
  export HTTP_CODE=$(docker run --rm --name fakeserver \
                                --entrypoint=curl \
                                ${CHE_SERVER_IMAGE_NAME}:${CHE_VERSION} \
                                  -I ${AGENT_INTERNAL_IP}:${AGENT_INTERNAL_PORT}/alpine-release \
                                  -s -o /dev/null \
                                  --write-out "%{http_code}")

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Che Server          => Workspace Agent (Internal IP): Connection succeeded"
  else
      info "Che Server          => Workspace Agent (Internal IP): Connection failed"
  fi

  docker rm -f fakeagent > /dev/null
}
