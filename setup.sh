#!/bin/sh

# operating system + architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# https://github.com/junegunn/fzf/releases, https://github.com/BurntSushi/ripgrep/releases, https://github.com/sharkdp/bat/releases, https://github.com/gokcehan/lf/releases
BAT_VERSION="0.24.0"
RIPGREP_VERSION="14.1.1"
FZF_VERSION="0.55.0"
LF_VERSION="r32"


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


install_deb() {
  URL=$1
  wget "$URL" -O temp.deb
  sudo dpkg -i temp.deb
}

install_tarball() {
  URL=$1
  wget "$URL" -O temp.tar.gz
  tar -xf temp.tar.gz
  sudo mv ./bat /usr/local/bin/
}

install_bat() {
  case "$OS" in
    linux)
      case "$ARCH" in
        amd64)
          install_deb "https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat_${BAT_VERSION}_amd64.deb"
          ;;
        arm64)
          install_deb "https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat_${BAT_VERSION}_arm64.deb"
          ;;
        armhf)
          install_deb "https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat_${BAT_VERSION}_armhf.deb"
          ;;
        i686)
          install_deb "https://github.com/sharkdp/bat/releases/download/v$BAT_VERSION/bat_${BAT_VERSION}_i686.deb"
          ;;
      esac
      ;;
    darwin)
      brew install bat
      ;;
    *)
      echo "Unsupported OS: $OS"
      ;;
  esac
}

install_ripgrep() {
  case "$OS" in
    linux)
      case "$ARCH" in
        amd64)
          install_deb "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep_$RIPGREP_VERSION-1_amd64.deb"
          ;;
        arm64)
          install_tarball "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-aarch64-unknown-linux-gnu.tar.gz"
          ;;
        armhf)
          install_tarball "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-armv7-unknown-linux-gnueabihf.tar.gz"
          ;;
        i686)
          install_tarball "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-i686-unknown-linux-gnu.tar.gz"
          ;;
      esac
      ;;
    darwin)
      brew install ripgrep
      ;;
    *)
      echo "Unsupported OS: $OS"
      ;;
  esac
}

install_fzf() {
  case "$OS" in
    linux)
      case "$ARCH" in
        amd64)
          install_tarball "https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_amd64.tar.gz"
          ;;
        arm64)
          install_tarball "https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_arm64.tar.gz"
          ;;
        armhf)
          install_tarball "https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_armv7.tar.gz"
          ;;
        i686)
          install_tarball "https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_386.tar.gz"
          ;;
      esac
      ;;
    darwin)
      brew install fzf
      ;;
    *)
      echo "Unsupported OS: $OS"
      ;;
  esac
}

install_lf() {
  case "$OS" in
    linux)
      case "$ARCH" in
        amd64)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-linux-amd64.tar.gz"
          ;;
        arm64)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-linux-arm64.tar.gz"
          ;;
        armhf)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-linux-arm.tar.gz"
          ;;
        i686)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-linux-386.tar.gz"
          ;;
      esac
      ;;
    darwin)
      case "$ARCH" in
        amd64)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-darwin-amd64.tar.gz"
          ;;
        arm64)
          install_tarball "https://github.com/gokcehan/lf/releases/download/$LF_VERSION/lf-darwin-arm64.tar.gz"
          ;;
        *)
          echo "Unsupported architecture for macOS: $ARCH"
          ;;
      esac    
      ;;
    *)
      echo "Unsupported OS: $OS"
      ;;
  esac
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
install_ripgrep
install_lf

add_lf_to_profile
install_lf_config

finalize
####################################################################################
