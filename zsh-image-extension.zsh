# -*- mode: shell-script -*-
# vim: ft=zsh fdm=marker :


# root dir of this plugin (assuming dirname of this file with resolved symlinks)
IMAGE_EXTENSION_DIR="${0:A:h}"

# default preview key: C-x C-o
IMAGE_EXTENSION_PREVIEW_KEY=${IMAGE_EXTENSION_PREVIEW_KEY:-'^X^O'}

# default selection key: C-x C-i
IMAGE_EXTENSION_SELECTION_KEY=${IMAGE_EXTENSION_SELECTION_KEY:-'^X^I'}

IMAGE_EXTENSION_PREVIEW_SCRIPT="$IMAGE_EXTENSION_DIR/image-preview.py"

# use the system-wide if the bundled one is not available
IMAGE_EXTENSION_SXIV=`whence sxiv`
echo $IMAGE_EXTENSION_SXIV


# if we have w3mimgdisplay available, enable the preview feature
if [ "$TERM" = "xterm-kitty" ]; then
    zsh-image-extension-preview-widget()
    {
        emulate -L zsh
        autoload -U split-shell-arguments
        setopt nullglob extended_glob

        # local variables for split-shell-arguments
        local reply REPLY REPLY2
        split-shell-arguments

        # expand globbing and unquote the arguments while omitting the arguments
        # containing only spaces
        eval "reply=(${reply:# #})"

        zsh-image-extension-preview $reply
    }
    zle -N zsh-image-extension-preview-widget
    bindkey $IMAGE_EXTENSION_PREVIEW_KEY zsh-image-extension-preview-widget

    zsh-image-extension-preview()
    {
        emulate -L zsh
        local KEY
        local OUTPUT
        #while [ "$KEY" != 'q' ]; do
            local IFS=$'\n'
            #OUTPUT=(`"$IMAGE_EXTENSION_PREVIEW_SCRIPT" "$@"`)
            #echo $OUTPUT
            OUTPUT=(`kitty +kitten icat "$@"`)
            #if [ "$?" != "0" ]; then
                #break
            #fi
            unset IFS
            #shift $OUTPUT[-1]

            #"$W3MIMGDISPLAY" &> /dev/null <<EOF
#echo ${(F)OUTPUT[1,-2]}
#EOF

            #read -s -k 1 KEY
            #if [ -n "$DISPLAY" -a "$IMAGE_EXTENSION_CLEAR_FALLBACK" != 1 ]; then
                #xrefresh -geometry $(xwininfo -id $WINDOWID | awk '
#/Absolute upper-left X:/ { x = $NF }
#/Absolute upper-left Y:/ { y = $NF }
#/Width:/                 { w = $NF }
#/Height:/                { h = $NF }
#END { printf "%sx%s+%s+%s", w,h,x,y }')
            #else
                #clear
                #zle && zle redisplay
            #fi
        #done
    }
    alias ils=zsh-image-extension-preview
fi





# if sxiv is available, enable the selection feature
if [ -x "$IMAGE_EXTENSION_SXIV" ]; then
    zsh-image-extension-selection-widget()
    {
        emulate -L zsh
        autoload -U modify-current-argument
        autoload -U split-shell-arguments
        setopt nullglob extended_glob

        # local variables for split-shell-arguments
        local reply REPLY REPLY2

        local ARG
        local PREFIX

        ((--CURSOR))
        split-shell-arguments
        ((++CURSOR))

        ARG="${reply[$REPLY]%% #}"

        # read the file prefix with trailing *'s stripped
        PREFIX=${ARG%%\*#}

        # If it is a directory, use its contents (i.e. it should end
        # up like ".../*" and not "...*") and deduplicate the traling
        # slashes.
        [ -d "$PREFIX" ] && PREFIX=${PREFIX%%/#}/

        local FILES
        eval "FILES=($PREFIX*(-.N))"
        [ -z "$FILES" ] && return

        local IFS=$'\n'
        FILES=($($IMAGE_EXTENSION_SXIV -o -- $FILES 2> /dev/null))
        unset IFS
        [ -z "$FILES" ] && return

        # quote the metacharacters
        FILES=$FILES:q

        if [ -n "$ARG" ]; then
            # Ignore the :-$ARG part. It's a hack to force
            # modify-current-argument to interpret it as an
            # expression and not a function.
            modify-current-argument '${FILES:-$ARG}'
        else
            LBUFFER="${LBUFFER%% #} $FILES"
        fi
    }
    zle -N zsh-image-extension-selection-widget
    bindkey $IMAGE_EXTENSION_SELECTION_KEY zsh-image-extension-selection-widget
fi
