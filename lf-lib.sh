#!/bin/sh

copy_2_clipboard() {
  case $(uname -s) in
      Linux*)     printf "${1}" | xsel --clipboard && return;;
      Darwin*)    printf "${1}" | pbcopy && return;;
  esac

  return 1
}

read_from_clipboard() {
  case $(uname -s) in
      Linux*)     xsel -ob && return;;
      Darwin*)    pbpaste && return;;
  esac

  return 1
}

yes_no_dialog() {
  title="${1}"
  text="${2}"
  if ! result=$( printf 'No\nYes' | fzf --margin=10,10,10,10 --bind "right:down"  --bind "left:up" --cycle --info=hidden --border-label="${2}" --border=double --height=26 --prompt "" )
  then
    return 1
  fi

  if [ "${result}" = "Yes" ]
  then
    return 0
  else
    return 1
  fi
}

read_input() {
  title="${1}"
  hint="${2}"
  text="${3}"

  exit_code='0'
  ( fzf --margin=10,10,10,10 --info=hidden --border-label="${title}" --border=double --height=4 --print-query --prompt "${hint}" --query="${text}" < /dev/null ) || exit_code="${?}"

  # when fzf returns an exit code equals to 1, it means there no matches, which is ok for input dialog
  if [ "${exit_code}" -eq 0 ] || [ "${exit_code}" -eq 1 ]
  then
    exit 0
  else
    exit 1
  fi
}

message_box() {
  text="${1}"
  cols=$( tput cols )
  edge=$( printf "%${cols}s" | sed 's/ /#/g' )

  echo -e "\n\n"
  echo "${edge}"
  echo "${text}"
  echo "${edge}"
  
  # press any key
  read -n 1 -s -r
}

menu() {
  set -e

  lfrc_menu="${HOME}/.config/lf/.menu"

  if [ ! -f "${lfrc_menu}" ]
  then
    message_box "The quick menu [${lfrc_menu}] file not found"
    return 1
  fi

  if ! result=$( cat -b "${lfrc_menu}" | sed 's/ |.*//' | grep . | fzf --margin=1,5,1,5 --cycle --bind "right:down" --bind "left:up" --layout=reverse --info=hidden  --border=double --height=30 --border-label=" Menu " --border=double --prompt "" )
  then
    return 0
  fi

  # retrieving the command number
  cmd_nr=$( printf "${result}" | awk '{print $1}' )

  # retrieving command
  command=$( cat "${lfrc_menu}" | grep . | sed -n "${cmd_nr}p" | sed 's/^[^|]*| //g' )

  echo "Executing the following command: [${command}]"
  sh -c "${command}"
}

find_files() {
  set -x
  export FZF_DEFAULT_COMMAND='find . -type f'

  if file=$( fzf ${1:-} --reverse --preview 'bat --paging=always --color=always {} 2>/dev/null || batcat --paging=always --color=always {} 2>/dev/null || cat' --bind 'tab:execute(open {} &>/dev/null )' --bind 'shift-tab:execute(open "$( dirname {})" )' --bind 'f3:execute(bat --paging=always --color=always {1} 2>/dev/null || batcat --paging=always --color=always {1} 2>/dev/null || less {1} )' --bind 'f4:execute(vi +{2} {1} )' )
    then
    lf -remote "send select \"${file}\""
  fi
}

find_in_files() {
  RG_PREFIX="rg ${1:-} --hidden --no-ignore --column --line-number --no-heading --color=always "
  selected=$( 
    FZF_DEFAULT_COMMAND="${RG_PREFIX} ''" \
    fzf ${1:-} \
        --ansi \
        --reverse \
        --disabled \
        --bind "change:reload:sleep 0.3; $RG_PREFIX {q} || true" \
        --bind 'f3:execute(bat --paging=always --color=always {1} --highlight-line {2} 2>/dev/null || batcat --paging=always --color=always {1} --highlight-line {2} 2>/dev/null || less {1} )' \
        --bind 'f4:execute(vi +{2} {1} )' \
        --bind 'tab:execute(open {1} &>/dev/null )' \
        --bind 'shift-tab:execute(open "$( dirname {1})" )' \
        --delimiter : \
        --preview 'bat --paging=always --color=always {1} --highlight-line {2} 2>/dev/null || batcat --paging=always --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}' \
        --preview-window 'right,50%,border-bottom,+{2}+3/3,~3'
  )

  item=$( printf "${selected}" | awk -F':' '{print $1}' )

  lf -remote "send select \"${item}\""
}

send_status() {
  lf -remote "send echo \"\033[1;33;47m ${1}\""
  sleep 5 && lf -remote 'send reload' &
}

gentle_change_dir() {
  dir_name="${1}"

  # does dir exist?
  if [ -d "${dir_name}" ]
  then
    lf -remote "send cd \"${dir_name}\""
    return 0
  fi

  if yes_no_dialog "Confirmation" "The [${dir_name}] directory doesn't exist. Do you want to create it and go into?"
  then
    mkdir -p "${dir_name}"
    lf -remote "send cd \"${dir_name}\""
  fi
}

provision_a_vm() {
  set -x

  img_url="${1}"
  url_hash=$( echo "${img_url}" | md5sum | awk '{print $1}' )

  # Prompt for VM name
  vm_name=$(read_input "Provision a VM" "VM name ")

  # Check if VM already exists
  if vboxmanage list vms | grep "\"${vm_name}" > /dev/null
  then
      if yes_no_dialog "" "The [${vm_name}] VM already exists. Override?"
      then
          vboxmanage unregistervm "${vm_name}" --delete
      else
          exit
      fi
  fi

  # Set OVA path and download if necessary
  ova_path="/tmp/${url_hash}.ova"
  if [ ! -f "${ova_path}" ]
  then
      wget -O "${ova_path}" "${img_url}"
  fi

  # Import and start the VM
  vboxmanage import "${ova_path}" --vsys 0 --vmname "${vm_name}"

  # Share a directory
  tmp_dir="${HOME}/tmp/vm-shared-dirs/${vm_name}"
  mkdir -p "${tmp_dir}"
  vboxmanage sharedfolder add "${vm_name}" --name "shared" --hostpath "${tmp_dir}" --automount

  # Start the VM
  vboxmanage startvm "${vm_name}" --type gui

  # Completion message
  echo "Done for [${vm_name}]"
}