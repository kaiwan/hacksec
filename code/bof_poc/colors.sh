#!/bin/bash
#-------- COLO[U]RS ! -------------------------------------------------
red_highlight() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[41m$*\e[0m"
}
red_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[31m$*\e[0m"
}
blue_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[34m$*\e[0m"
}
lightblue_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[36m$*\e[0m"
}
green_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[32m$*\e[0m"
}
purple_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[35m$*\e[0m"
}
yellow_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[33m$*\e[0m"
}
gray_fg() {
        [[ $# -eq 0 ]] && return
        echo -e "\e[1m\e[30m$*\e[0m"
}
#----------------------------------------------------------------------
bold() {
        [[ $# -eq 0 ]] && return
	echo -e "\033[1m$*\e[0m"
}
