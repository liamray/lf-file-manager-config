#!/bin/sh

CONFIG_FILE="main.zip"
CONFIG_SOURCE="https://github.com/liamray/lf-file-manager-config/archive/refs/heads/${CONFIG_FILE}"

set -eux
if ! which sudo >/dev/null
then
        alias sudo=''
fi

init() {
        tmp_dir=$( mktemp -d )
        trap "rm -rf ${tmp_dir}" EXIT
        cd "${tmp_dir}"
}

download_binaries() {
        # macos
        if which brew >/dev/null
        then
                # todo: test it
                brew install pbcopy
                return
        fi

        # debian*
        if which apt >/dev/null
        then
                sudo apt -qq update
                sudo DEBIAN_FRONTEND=noninteractive apt -qq install zip unzip wget xsel vim fzf ripgrep less jq -y
                return
        fi

        # rh
        if which yum >/dev/null
        then
                # todo: test it
                sudo yum update
                sudo yum install zip unzip zip unzip wget xsel vim fzf ripgrep less jq -y
                return
        fi

        # alpine
        if which apk >/dev/null
        then
                apk add newt
                return
        fi
}

download_config() {        
        wget "${CONFIG_SOURCE}"

        lf_dir="${HOME}/.config/lf"
        mkdir -p "${lf_dir}"

        unzip -j "${CONFIG_FILE}" -d "${lf_dir}"
}

install_lf() {
        # downloading
        latest_lf_url=$( curl -s https://api.github.com/repos/gokcehan/lf/releases/latest | jq -r '.assets[] | select(.name == "lf-linux-386.tar.gz") | .browser_download_url' )
        wget "${latest_lf_url}"

        # extracting and moving
        tar -zxvf lf-linux-386.tar.gz
        sudo mv ./lf /usr/local/bin

        profile="${HOME}/.profile"

        # lf() function already in the .profile?
        if [ -f "${profile}" ] && cat "${profile}" | grep 'lf()'
        then
                # already there
                return
        fi

        # the original lf path which will be replaced with the lf() function
        lf_runner=$( which lf )

        # adding the lf() function to the .profile
        cat << EOF >> "${profile}"

export LF_COLORS="\
~/Downloads=01;31:\
~/workspaces=01;31:\
~/tmp=01;31:\
~/.local/share=01;31:\
~/.config/lf/lfrc=31:\
.git/=01;32:\
.git*=32:\
*.gitignore=32:\
*Makefile=32:\
README.*=33:\
*.txt=34:\
*.md=34:\
ln=01;36:\
di=01;34:\
ex=01;32:\
"

lf() {
        # this file stores a recent directory location in lf
        lf_last_path="\${HOME}/.config/lf/.lastpath"

        # running the lf
        ${lf_runner} -last-dir-path="\${lf_last_path}"

        # changing dir
        lf_path=\$( cat "\${lf_last_path}" )
        cd "\${lf_path}"
}

EOF

        # sourcing
        set +eux
        . "${profile}"
}

init
download_binaries
download_config
install_lf
