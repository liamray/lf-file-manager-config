#!/bin/sh

# operating system + architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# https://github.com/junegunn/fzf/releases
FZF_VERSION='0.55.0'

# https://github.com/BurntSushi/ripgrep/releases
RG_VERSION='14.1.1'

# https://github.com/sharkdp/bat/releases
BAT_VERSION='0.24.0'

# https://github.com/gokcehan/lf/releases
LF_VERSION='r32'

# lf config file location in GitHub
LF_CONFIG_FILE="main.zip"
LF_CONFIG_URL="https://github.com/liamray/lf-file-manager-config/archive/refs/heads/${LF_CONFIG_FILE}"


init() {
        # handling shell opts
        old_opts="${-}"
        eux_opts=$( echo "${old_opts}" | grep -o '[eux]' | tr -d '\n' )
        set -eux

        # handling sudo
        if ! which sudo >/dev/null
        then
                alias sudo=''
        fi

        # creating tmp dir + self destroy hook
        tmp_dir=$( mktemp -d )
        trap "rm -rf ${tmp_dir}" EXIT
        cd "${tmp_dir}"
}



install_common_packages() {
        # macos
        if [ "${OS}" = 'darwin' ]
        then
                brew install zip unzip wget xsel vim ripgrep less jq bat                
                return
        fi

        # non linux
        if [ "${OS}" != 'linux' ]
        then
                echo 'Unsupported [${OS}] OS'
                exit 1
        fi

        # debian
        if [ -f /etc/debian_version ]
        then
                sudo DEBIAN_FRONTEND=noninteractive apt -qq update
                sudo DEBIAN_FRONTEND=noninteractive apt -qq install zip unzip wget xsel vim ripgrep less jq bat -y
                return
        fi

        # rh
        if [ -f /etc/redhat-release ]
        then
                if command -v dnf > /dev/null 2>&1
                then
                        sudo dnf install -y zip unzip wget xsel vim ripgrep less jq bat
                        return
                fi

                if command -v yum > /dev/null 2>&1
                then
                        sudo yum install -y zip unzip wget xsel vim ripgrep less jq bat
                        return
                fi
                
                echo 'Unsupported package manager for RH Linux'
                exit 1
        fi

        # arch
        if [ -f /etc/arch-release ]
        then
                sudo pacman -Sy --noconfirm zip unzip wget xsel vim ripgrep less jq bat
                return
        fi

        echo 'Unsupported Linux release'
        exit 1
}

install_fzf() {
        if which fzf
        then
                echo '-----------------------'
                echo "fzf is already installed, the minimum recommended version is [${FZF_VERSION}]"
                return        
        fi

        case "${ARCH}" in
                "x86_64") ARCH="amd64" ;;
                "armv5l") ARCH="armv5" ;;
                "armv6l") ARCH="armv6" ;;
                "armv7l") ARCH="armv7" ;;
                "aarch64") ARCH="arm64" ;;
                "ppc64le") ARCH="ppc64le" ;;
                "s390x") ARCH="s390x" ;;
                "loongarch64") ARCH="loong64" ;;
                *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
        esac

        # Determine the correct file to download
        file_name="fzf-${FZF_VERSION}-${OS}_${ARCH}.tar.gz"
        download_url="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/${file_name}"

        # downloading the file
        wget -O "${file_name}" "${download_url}"

        # extract the tarball
        tar -xzf "${file_name}"

        # move the binary to /usr/local/bin or ~/bin
        if [ -d "/usr/local/bin" ]
        then
                sudo mv fzf /usr/local/bin/
        else
                mkdir -p ~/bin
                mv fzf ~/bin/
        fi
}

install_bat() {
        # still not working
        exit 1
        # already installed?
        if which bat || which batcat
        then
                echo '-----------------------'
                echo 'bat is already installed'
                return
        fi

        case "${ARCH}" in
                "x86_64") ARCH="x86_64" ;;
                "i386" | "i686") ARCH="i686" ;;
                "armv7l") ARCH="arm" ;;
                "aarch64") ARCH="aarch64" ;;
                *) echo "Unsupported architecture: ${ARCH}"; exit 1 ;;
        esac

        if [ "${OS}" = "linux" ]; then
                case "$ARCH" in
                        "x86_64") file_name="bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz" ;;
                        "i686") file_name="bat-v${BAT_VERSION}-i686-unknown-linux-gnu.tar.gz" ;;
                        "arm") file_name="bat-v${BAT_VERSION}-arm-unknown-linux-gnueabihf.tar.gz" ;;
                        "aarch64") file_name="bat-v${BAT_VERSION}-aarch64-unknown-linux-gnu.tar.gz" ;;
                        *) echo "Unsupported architecture for Linux: ${ARCH}"; exit 1 ;;
                esac
        fi
        
        if [ "${OS}" = "darwin" ]
        then
                file_name="bat-v${BAT_VERSION}-x86_64-apple-darwin.tar.gz"
        fi

        download_url="https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/${file_name}"

        # downloading the file
        wget -O "${file_name}" "${download_url}"

        # is .deb package?
        if [ "${FILENAME##*.}" = "deb" ]
        then
                sudo dpkg -i "$file_name"
                return
        fi

        # handling tar.gz
        tar -xzf "${file_name}"

        # move the binary to /usr/local/bin or ~/bin
        if [ -d "/usr/local/bin" ]
        then
                sudo mv bat /usr/local/bin/
        else
                mkdir -p ~/bin
                mv bat ~/bin/
        fi
}


install_rg() {
        :
}

install_lf() {
        # already installed?
        if which lf
        then
                echo '-----------------------'
                echo 'lf is already installed'
                return
        fi

        case "${ARCH}" in
                "x86_64") ARCH="amd64" ;;
                "i386" | "i686") ARCH="386" ;;
                "armv7l") ARCH="arm" ;;
                "aarch64") ARCH="arm64" ;;
                "ppc64le") ARCH="ppc64le" ;;
                "ppc64") ARCH="ppc64" ;;
                "mips64") ARCH="mips64" ;;
                "mips64el") ARCH="mips64le" ;;
                "mips") ARCH="mips" ;;
                "mipsel") ARCH="mipsle" ;;
                "s390x") ARCH="s390x" ;;
                *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
        esac

        if [ "$OS" = "sunos" ]; then
                OS="illumos"
        fi

        file_name="lf-${OS}-${ARCH}.tar.gz"
        download_url="https://github.com/gokcehan/lf/releases/download/${LF_VERSION}/${file_name}"

        # downloading the file
        wget -O "${file_name}" "${download_url}"

        # extract the tarball
        tar -xzf "${file_name}"

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

finalize() {
        # all done
        set +x
        echo
        echo '-----------------------------------'
        echo 'All Done!'
        echo 'Type lf to start the file manager'
        echo '-----------------------------------'

        # restoring the opts
        set +eux
        set -${eux_opts}
}

####################################################################################
init

install_common_packages

install_fzf
install_bat
install_rg
install_lf

add_lf_to_profile
install_lf_config

finalize
####################################################################################
