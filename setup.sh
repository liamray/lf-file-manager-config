#!/bin/sh

set -eux

LF_CONFIG_FILE="main.zip"
LF_CONFIG_URL="https://github.com/liamray/lf-file-manager-config/archive/refs/heads/${LF_CONFIG_FILE}"

init() {
        if ! which sudo >/dev/null
        then
                alias sudo=''
        fi
}

create_temp_dir() {
        tmp_dir=$( mktemp -d )
        trap "rm -rf ${tmp_dir}" EXIT
        cd "${tmp_dir}"
}

install_common_packages() {
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
                sudo DEBIAN_FRONTEND=noninteractive apt -qq install zip unzip wget xsel vim ripgrep less jq bat -y
                return
        fi

        # rh
        if which yum >/dev/null
        then
                # todo: test it
                sudo yum update
                sudo yum install zip unzip zip unzip wget xsel vim ripgrep less jq bat -y
                return
        fi

        # alpine
        if which apk >/dev/null
        then
                apk add newt
                return
        fi
}

gh_latest_version() {
        wget -qO- https://api.github.com/repos/${1}/releases/latest | jq -r '.tag_name'
}

detect_os_arch_for_fzf() {
        OS=$(uname | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)

        case $OS in
        linux)
                case $ARCH in
                x86_64) printf "linux_amd64" ;;
                aarch64) printf "linux_arm64" ;;
                armv5*) printf "linux_armv5" ;;
                armv6*) printf "linux_armv6" ;;
                armv7*) printf "linux_armv7" ;;
                loong64) printf "linux_loong64" ;;
                ppc64le) printf "linux_ppc64le" ;;
                *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
                esac
                ;;
        darwin)
                case $ARCH in
                x86_64) printf "darwin_amd64" ;;
                arm64) printf "darwin_arm64" ;;
                *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
                esac
                ;;
        freebsd)
                case $ARCH in
                x86_64) printf "freebsd_amd64" ;;
                *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
                esac
                ;;
        *)
                echo "Unsupported operating system: $OS"
                exit 1
                ;;
        esac
}

install_fzf() {
        BINARY=$(detect_os_arch_for_fzf)
        VERSION=$(gh_latest_version 'junegunn/fzf')
        URL="https://github.com/junegunn/fzf/releases/download/${VERSION}/fzf-${VERSION#?}-${BINARY}.tar.gz"

        # download binary
        wget -O fzf.tar.gz "${URL}"

        # extract it
        tar -xzf fzf.tar.gz

        # move the binary to /usr/local/bin or ~/bin
        if [ -d "/usr/local/bin" ]
        then
                sudo mv fzf /usr/local/bin/
        else
                mkdir -p ~/bin
                mv fzf ~/bin/
        fi

}

detect_os_arch_for_lf() {
        OS="$(uname -s)"
        ARCH="$(uname -m)"

        case "$OS" in
        Linux)
                OS="linux"
                ;;
        Darwin)
                OS="darwin"
                ;;
        FreeBSD)
                OS="freebsd"
                ;;
        DragonFly)
                OS="dragonfly"
                ;;
        SunOS)
                OS="illumos"
                ;;
        Android)
                OS="android"
                ;;
        *)
                echo "Unsupported operating system: $OS"
                exit 1
                ;;
        esac

        case "$ARCH" in
        x86_64)
                ARCH="amd64"
                ;;
        aarch64 | arm64)
                ARCH="arm64"
                ;;
        i386 | i686)
                ARCH="386"
                ;;
        arm*)
                ARCH="arm"
                ;;
        *)
                echo "Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac

        echo "${OS}-${ARCH}"
}

install_lf() {
        # get the latest release tag from GitHub using jq
        LATEST_RELEASE=$(gh_latest_version 'gokcehan/lf')

        # ff LATEST_RELEASE is empty, exit with an error
        if [ -z "${LATEST_RELEASE}" ]
        then
                echo "Failed to get the latest release."
                exit 1
        fi

        # detect OS and architecture
        OS_ARCH=$(detect_os_arch_for_lf)

        # construct the download URL
        BASE_URL="https://github.com/gokcehan/lf/releases/download/${LATEST_RELEASE}"
        FILE_NAME="lf-${OS_ARCH}.tar.gz"
        DOWNLOAD_URL="${BASE_URL}/${FILE_NAME}"

        # download the file
        wget -O "${FILE_NAME}" "${DOWNLOAD_URL}"

        # extract the tarball
        tar -xzf "$FILE_NAME"

        # move the binary to /usr/local/bin or ~/bin
        if [ -d "/usr/local/bin" ]
        then
                sudo mv lf /usr/local/bin/
        else
                mkdir -p ~/bin
                mv lf ~/bin/
        fi
}

append_script() {
        local file="$1"

        if cat "${file}" | grep 'lf()'
        then
                return
        fi

        # the original lf path which will be replaced with the lf() function
        lf_runner=$( which lf )

        # adding the lf() function to the .profile
        cat << EOF >> "${file}"

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
        . "${file}"
        set -eux
}

add_lf_to_profile() {
        # detect the operating system
        os=$(uname -s)

        case "$os" in
        Linux)
                shell=$(basename "$SHELL")

                case "$shell" in
                bash)
                        append_script "$HOME/.bashrc"
                        ;;
                zsh)
                        append_script "$HOME/.zshrc"
                        ;;
                ksh)
                        append_script "$HOME/.kshrc"
                        ;;
                *)
                        echo "Unsupported shell: $shell"
                        exit 1
                        ;;
                esac
                ;;
        Darwin)
                shell=$(basename "$SHELL")
                
                case "$shell" in
                bash)
                        append_script "$HOME/.bash_profile"
                        ;;
                zsh)
                        append_script "$HOME/.zshrc"
                        ;;
                *)
                        echo "Unsupported shell: $shell"
                        exit 1
                        ;;
                esac
                ;;
        *)
                echo "Unsupported OS: $os"
                exit 1
                ;;
        esac
}

install_lf_config() {        
        wget "${LF_CONFIG_URL}"

        lf_dir="${HOME}/.config/lf"
        mkdir -p "${lf_dir}"

        unzip -j "${LF_CONFIG_FILE}" -d "${lf_dir}"
}


####################################################################################
init
create_temp_dir
install_common_packages
install_fzf
install_lf
add_lf_to_profile
install_lf_config
####################################################################################
