#!/bin/sh

set -eux
if ! which sudo >/dev/null
then
        alias sudo=''
fi

init() {
        tmpDir=$( mktemp -d )
        trap "rm -rf ${tmpDir}" EXIT
        cd "${tmpDir}"
}

downloadBinaries() {
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
                sudo apt update
                sudo apt install unzip wget whiptail xsel less vim psmisc -y
                return
        fi

        # rh
        if which yum >/dev/null
        then
                # todo: test it
                sudo yum update
                sudo yum install unzip wget whiptail xsel vim less psmisc -y
                return
        fi

        # alpine
        if which apk >/dev/null
        then
                apk add newt
                return
        fi
}

downloadConfig() {        
        wget "https://github.com/liamray/fm/archive/refs/heads/main.zip"
        unzip -j main.zip
        rm -rf main.zip
        lfDir="${HOME}/.config/lf"
        mkdir -p "${lfDir}"
        cp * "${lfDir}"
}

installlf() {
        # downloading
        wget 'https://github.com/gokcehan/lf/releases/download/r30/lf-linux-386.tar.gz'
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
        lfPath=$( which lf )

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
        export LF_SETTINGS_DIR="\${HOME}/.config/lf/.settings"
        mkdir -p "\${LF_SETTINGS_DIR}"
        lfLastPath="\${LF_SETTINGS_DIR}/last-path"
        ${lfPath} -last-dir-path="\${lfLastPath}"
        lastPath=\$( cat "\${lfLastPath}" )
        cd "\${lastPath}"
}

EOF

        # sourcing
        set +eux
        . "${profile}"
}

init
downloadBinaries
downloadConfig
installlf
