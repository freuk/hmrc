#!/usr/bin/env sh

# #############################################################################
# Description: Sample script to play files in apps by file type or mime
#
# Shell: POSIX compliant
# Usage: nuke filepath
#
# Integration with nnn:
#   1. Export the required config:
#         export NNN_OPENER=/absolute/path/to/nuke
#         # Otherwise, if nuke is in $PATH
#         # export NNN_OPENER=nuke
#   2. Run nnn with the program option to indicate a CLI opener
#         nnn -c
#         # The -c program option overrides option -e
#   3. nuke can use nnn plugins (e.g. mocplay is used for audio), $PATH is updated.
#
# Details:
#   Inspired by ranger's scope.sh, modified for usage with nnn.
#
#   Guards against accidentally opening mime types like executables, shared libs etc.
#
#   Tries to play 'file' (1st argument) in the following order:
#   i. by extension
#   ii. by mime (image, video, audio, pdf)
#   iii. by mime (other file types)
#
# Modification tips:
#   1. Invokes CLI utilities by default. Set GUI to 1 to enable GUI apps.
#   2. PAGER is "less -R".
#   3. Start GUI apps in bg to unblock. Redirect stdout and strerr if required.
#   4. Some CLI utilities are piped to the $PAGER, to wait and quit uniformly.
#   5. If the output cannot be paged use "read -r _" to wait for user input.
#   6. On a DE, try 'xdg-open' or 'open' in handle_fallback() as last resort.
#
#   Feel free to change the utilities to your favourites and add more mimes.
#
# Defaults:
#   By extension (only the enabled ones):
#      most archives: list with atool, bsdtar
#      rar: list with unrar
#      7-zip: list with 7z
#      pdf: zathura (GUI), pdftotext, mutool, exiftool
#      audio: mocplay (nnn plugin using MOC), mpv, media_client (Haiku), mediainfo, exiftool
#      avi|mkv|mp4: smplayer, mpv (GUI), ffmpegthumbnailer, mediainfo, exiftool
#      log: vi
#      torrent: rtorrent, transmission-show
#      odt|ods|odp|sxw: odt2txt
#      md: glow (https://github.com/charmbracelet/glow), lowdown (https://kristaps.bsd.lv/lowdown)
#      htm|html|xhtml: w3m, lynx, elinks
#      json: jq, python (json.tool module)
#   Multimedia by mime:
#      image/*: imv/sxiv (GUI), viu (https://github.com/atanunq/viu), img2txt, exiftool
#      video/*: smplayer, mpv (GUI), ffmpegthumbnailer, mediainfo, exiftool
#      audio/*: mocplay (nnn plugin using MOC), mpv, media_client (Haiku), mediainfo, exiftool
#      application/pdf: zathura (GUI), pdftotext, mutool, exiftool
#   Other mimes:
#      text/troff: man -l
#      text/* | */xml: vi
#      image/vnd.djvu): djvutxt, exiftool
#
# ToDo:
#   1. Adapt, test and enable all mimes
#   2. Clean-up the unnecessary exit codes
# #############################################################################

# set to 1 to enable GUI apps
GUI="${GUI:-1}"

set -euf -o noclobber -o noglob -o nounset
IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}" # protect trailing \n

PATH=$PATH:"${XDG_CONFIG_HOME:-$HOME/.config}/nnn/plugins"
IMAGE_CACHE_PATH="$(dirname "$1")"/.thumbs

FPATH="$1"
FNAME=$(basename "$1")
EDITOR="${EDITOR:-vi}"
PAGER="${PAGER:-less -R}"
ext="${FNAME##*.}"
if [ -n "$ext" ]; then
    ext="$(printf "%s" "${ext}" | tr '[:upper:]' '[:lower:]')"
fi

is_mac() {
    uname | grep -q "Darwin"
}

handle_pdf() {
    if [ "$GUI" -ne 0 ] && is_mac; then
        open "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif [ "$GUI" -ne 0 ] && which zathura >/dev/null 2>&1; then
        zathura "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif which pdftotext >/dev/null 2>&1; then
        ## Preview as text conversion
        pdftotext -l 10 -nopgbrk -q -- "${FPATH}" - | eval "$PAGER"
        exit 0
    elif which mutool >/dev/null 2>&1; then
        mutool draw -F txt -i -- "${FPATH}" 1-10 | eval "$PAGER"
        exit 0
    elif which exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}" | eval "$PAGER"
        exit 0
    fi
}

handle_audio() {
    if which mocp >/dev/null 2>&1 && which mocplay >/dev/null 2>&1; then
        mocplay "${FPATH}" "opener" >/dev/null 2>&1
        exit 0
    elif which mpv >/dev/null 2>&1; then
        mpv "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif which media_client >/dev/null 2>&1; then
        media_client play "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif which mediainfo >/dev/null 2>&1; then
        mediainfo "${FPATH}" | eval "$PAGER"
        exit 0
    elif which exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}"| eval "$PAGER"
        exit 0
    fi
}

handle_video() {
    if [ "$GUI" -ne 0 ] && is_mac; then
        open "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif [ "$GUI" -ne 0 ] && which smplayer >/dev/null 2>&1; then
        smplayer "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif [ "$GUI" -ne 0 ] && which mpv >/dev/null 2>&1; then
        mpv "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif which ffmpegthumbnailer >/dev/null 2>&1; then
        # Thumbnail
        [ -d "${IMAGE_CACHE_PATH}" ] || mkdir "${IMAGE_CACHE_PATH}"
        ffmpegthumbnailer -i "${FPATH}" -o "${IMAGE_CACHE_PATH}/${FNAME}.jpg" -s 0
        viu -n "${IMAGE_CACHE_PATH}/${FNAME}.jpg" | eval "$PAGER"
        exit 0
    elif which mediainfo >/dev/null 2>&1; then
        mediainfo "${FPATH}" | eval "$PAGER"
        exit 0
    elif which exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}"| eval "$PAGER"
        exit 0
    fi
}

# handle this extension and exit
handle_extension() {
    case "${ext}" in
        ## Archive
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            if which atool >/dev/null 2>&1; then
                atool --list -- "${FPATH}" | eval "$PAGER"
                exit 0
            elif which bsdtar >/dev/null 2>&1; then
                bsdtar --list --file "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;
        rar)
            if which unrar >/dev/null 2>&1; then
                ## Avoid password prompt by providing empty password
                unrar lt -p- -- "${FPATH}" | eval "$PAGER"
            fi
            exit 1;;
        7z)
            if which 7z >/dev/null 2>&1; then
                ## Avoid password prompt by providing empty password
                7z l -p -- "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;

        ## PDF
        pdf)
            handle_pdf
            exit 1;;

        ## Audio
        aac|flac|m4a|mid|midi|mpa|mp2|mp3|ogg|wav|wma)
            handle_audio
            exit 1;;

        ## Video
        avi|mkv|mp4)
            handle_video
            exit 1;;

        ## Log files
        log)
            "$EDITOR" "${FPATH}"
            exit 0;;

        ## BitTorrent
        torrent)
            if which rtorrent >/dev/null 2>&1; then
                rtorrent "${FPATH}"
                exit 0
            elif which transmission-show >/dev/null 2>&1; then
                transmission-show -- "${FPATH}"
                exit 0
            fi
            exit 1;;

        ## OpenDocument
        odt|ods|odp|sxw)
            if which odt2txt >/dev/null 2>&1; then
                ## Preview as text conversion
                odt2txt "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;

        ## Markdown
        md)
            if which glow >/dev/null 2>&1; then
                glow -sdark "${FPATH}" | eval "$PAGER"
                exit 0
            elif which lowdown >/dev/null 2>&1; then
                lowdown -Tterm "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            ;;

        ## HTML
        # htm|html|xhtml)
        #     ## Preview as text conversion
        #     if which w3m >/dev/null 2>&1; then
        #         w3m -dump "${FPATH}" | eval "$PAGER"
        #         exit 0
        #     elif which lynx >/dev/null 2>&1; then
        #         lynx -dump -- "${FPATH}" | eval "$PAGER"
        #         exit 0
        #     elif which elinks >/dev/null 2>&1; then
        #         elinks -dump "${FPATH}" | eval "$PAGER"
        #         exit 0
        #     fi
        #     ;;

        ## JSON
        json)
            if which jq >/dev/null 2>&1; then
                jq --color-output . "${FPATH}" | eval "$PAGER"
                exit 0
            elif which python >/dev/null 2>&1; then
                python -m json.tool -- "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            ;;
    esac
}

abspath() {
    case "$1" in
        /*) printf "%s\n" "$1";;
        *)  printf "%s\n" "$PWD/$1";;
    esac
}

listimages() {
    find -L "$(dirname "$target")" -maxdepth 1 -type f -iregex \
      '.*\(jpe?g\|bmp\|webp\|png\|gif\)$' -print0 | sort -z
}

load_dir() {
    target="$(abspath "$2")"
    count="$(listimages | grep -a -m 1 -ZznF "$target" | cut -d: -f1)"

    if [ -n "$count" ]; then
        listimages | xargs -0 "$1" -n "$count" --
    else
        shift
        "$1" -- "$@" # fallback
    fi
}

handle_multimedia() {
    ## Size of the preview if there are multiple options or it has to be
    ## rendered from vector graphics. If the conversion program allows
    ## specifying only one dimension while keeping the aspect ratio, the width
    ## will be used.
    # local DEFAULT_SIZE="1920x1080"

    mimetype="${1}"
    case "${mimetype}" in
        ## SVG
        # image/svg+xml|image/svg)
        #     convert -- "${FPATH}" "${IMAGE_CACHE_PATH}" && exit 6
        #     exit 1;;

        ## DjVu
        # image/vnd.djvu)
        #     ddjvu -format=tiff -quality=90 -page=1 -size="${DEFAULT_SIZE}" \
        #           - "${IMAGE_CACHE_PATH}" < "${FPATH}" \
        #           && exit 6 || exit 1;;

        ## Image
        image/*)
            if [ "$GUI" -ne 0 ] && is_mac; then
                open "${FPATH}" >/dev/null 2>&1 &
                exit 0
            elif [ "$GUI" -ne 0 ] && which imvr >/dev/null 2>&1; then
                load_dir imvr "${FPATH}" >/dev/null 2>&1 &
                exit 0
            elif [ "$GUI" -ne 0 ] && which sxiv >/dev/null 2>&1; then
                load_dir sxiv "${FPATH}" >/dev/null 2>&1 &
                exit 0
            elif which viu >/dev/null 2>&1; then
                viu -n "${FPATH}" | eval "$PAGER"
                exit 0
            elif which img2txt >/dev/null 2>&1; then
                img2txt --gamma=0.6 -- "${FPATH}" | eval "$PAGER"
                exit 0
            elif which exiftool >/dev/null 2>&1; then
                exiftool "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            # local orientation
            # orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${FPATH}" )"
            ## If orientation data is present and the image actually
            ## needs rotating ("1" means no rotation)...
            # if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                ## ...auto-rotate the image according to the EXIF data.
                # convert -- "${FPATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
            # fi

            ## `w3mimgdisplay` will be called for all images (unless overridden
            ## as above), but might fail for unsupported types.
            exit 7;;

        ## PDF
        application/pdf)
            handle_pdf
            exit 1;;

        ## Audio
        audio/*)
            handle_audio
            exit 1;;

        ## Video
        video/*)
            handle_video
            exit 1;;

        #     pdftoppm -f 1 -l 1 \
        #              -scale-to-x "${DEFAULT_SIZE%x*}" \
        #              -scale-to-y -1 \
        #              -singlefile \
        #              -jpeg -tiffcompression jpeg \
        #              -- "${FPATH}" "${IMAGE_CACHE_PATH%.*}" \
        #         && exit 6 || exit 1;;


        ## ePub, MOBI, FB2 (using Calibre)
        # application/epub+zip|application/x-mobipocket-ebook|\
        # application/x-fictionbook+xml)
        #     # ePub (using https://github.com/marianosimone/epub-thumbnailer)
        #     epub-thumbnailer "${FPATH}" "${IMAGE_CACHE_PATH}" \
        #         "${DEFAULT_SIZE%x*}" && exit 6
        #     ebook-meta --get-cover="${IMAGE_CACHE_PATH}" -- "${FPATH}" \
        #         >/dev/null && exit 6
        #     exit 1;;

        ## Font
        # application/font*|application/*opentype)
        #     preview_png="/tmp/$(basename "${IMAGE_CACHE_PATH%.*}").png"
        #     if fontimage -o "${preview_png}" \
        #                  --pixelsize "120" \
        #                  --fontname \
        #                  --pixelsize "80" \
        #                  --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
        #                  --text "  abcdefghijklmnopqrstuvwxyz  " \
        #                  --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
        #                  --text "  The quick brown fox jumps over the lazy dog.  " \
        #                  "${FPATH}";
        #     then
        #         convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" \
        #             && rm "${preview_png}" \
        #             && exit 6
        #     else
        #         exit 1
        #     fi
        #     ;;

        ## Preview archives using the first image inside.
        ## (Very useful for comic book collections for example.)
        # application/zip|application/x-rar|application/x-7z-compressed|\
        #     application/x-xz|application/x-bzip2|application/x-gzip|application/x-tar)
        #     local fn=""; local fe=""
        #     local zip=""; local rar=""; local tar=""; local bsd=""
        #     case "${mimetype}" in
        #         application/zip) zip=1 ;;
        #         application/x-rar) rar=1 ;;
        #         application/x-7z-compressed) ;;
        #         *) tar=1 ;;
        #     esac
        #     { [ "$tar" ] && fn=$(tar --list --file "${FPATH}"); } || \
        #     { fn=$(bsdtar --list --file "${FPATH}") && bsd=1 && tar=""; } || \
        #     { [ "$rar" ] && fn=$(unrar lb -p- -- "${FPATH}"); } || \
        #     { [ "$zip" ] && fn=$(zipinfo -1 -- "${FPATH}"); } || return
        #
        #     fn=$(echo "$fn" | python -c "import sys; import mimetypes as m; \
        #             [ print(l, end='') for l in sys.stdin if \
        #               (m.guess_type(l[:-1])[0] or '').startswith('image/') ]" |\
        #         sort -V | head -n 1)
        #     [ "$fn" = "" ] && return
        #     [ "$bsd" ] && fn=$(printf '%b' "$fn")
        #
        #     [ "$tar" ] && tar --extract --to-stdout \
        #         --file "${FPATH}" -- "$fn" > "${IMAGE_CACHE_PATH}" && exit 6
        #     fe=$(echo -n "$fn" | sed 's/[][*?\]/\\\0/g')
        #     [ "$bsd" ] && bsdtar --extract --to-stdout \
        #         --file "${FPATH}" -- "$fe" > "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$bsd" ] || [ "$tar" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     [ "$rar" ] && unrar p -p- -inul -- "${FPATH}" "$fn" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$zip" ] && unzip -pP "" -- "${FPATH}" "$fe" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$rar" ] || [ "$zip" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     ;;
    esac
}

handle_mime() {
    mimetype="${1}"
    case "${mimetype}" in
        ## Manpages
        text/troff)
            man -l "${FPATH}"
            exit 0;;

        ## Text
        text/* | */xml)
            "$EDITOR" "${FPATH}"
            exit 0;;
            ## Syntax highlight
            # if [[ "$( stat --printf='%s' -- "${FPATH}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
            #     exit 2
            # fi
            # if [[ "$( tput colors )" -ge 256 ]]; then
            #     local pygmentize_format='terminal256'
            #     local highlight_format='xterm256'
            # else
            #     local pygmentize_format='terminal'
            #     local highlight_format='ansi'
            # fi
            # env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight \
            #     --out-format="${highlight_format}" \
            #     --force -- "${FPATH}" && exit 5
            # pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}"\
            #     -- "${FPATH}" && exit 5
            # exit 2;;

        ## DjVu
        image/vnd.djvu)
            if which djvutxt >/dev/null 2>&1; then
                ## Preview as text conversion (requires djvulibre)
                djvutxt "${FPATH}" | eval "$PAGER"
                exit 0
            elif which exiftool >/dev/null 2>&1; then
                exiftool "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;
    esac
}

handle_fallback() {
    if [ "$GUI" -ne 0 ] && which xdg-open >/dev/null 2>&1; then
        xdg-open "${FPATH}" >/dev/null 2>&1 &
        exit 0
    elif [ "$GUI" -ne 0 ] && which open >/dev/null 2>&1; then
        open "${FPATH}" >/dev/null 2>&1 &
        exit 0
    fi

    echo '----- File details -----' && file --dereference --brief -- "${FPATH}"
    exit 1
}

handle_blocked() {
    case "${MIMETYPE}" in
        application/x-sharedlib)
            exit 0;;

        application/x-shared-library-la)
            exit 0;;

        application/x-executable)
            exit 0;;

        application/x-shellscript)
            exit 0;;

        application/octet-stream)
            exit 0;;
    esac
}

MIMETYPE="$( file --dereference --brief --mime-type -- "${FPATH}" )"
handle_extension
echo $GUI
handle_multimedia "${MIMETYPE}"
handle_mime "${MIMETYPE}"
handle_blocked "${MIMETYPE}"
handle_fallback

exit 1
