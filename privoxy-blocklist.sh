#!/bin/bash
#
######################################################################
#
#                  Author: Andrwe Lord Weber
#                  Mail: lord-weber-andrwe<at>renona-studios<dot>org
#                  Version: 0.2
#                  URL: http://andrwe.org/scripting/bash/privoxy-blocklist
#                  Modified a tiny bit by Etienne Perot
#
##################
#
#                  Sumary: 
#                   This script downloads, converts and installs
#                   AdblockPlus lists into Privoxy
#
######################################################################

######################################################################
#
#                 TODO:
#                  - implement:
#                     domain-based filter
#
######################################################################

######################################################################
#
#                  script variables and functions
#
######################################################################

# array of URL for AdblockPlus lists
URLS=("https://easylist-downloads.adblockplus.org/liste_fr+easylist.txt" "https://easylist-downloads.adblockplus.org/easyprivacy.txt" "http://adversity.googlecode.com/hg/Antisocial.txt" "http://lian.info.tm/liste_fr.txt")
# privoxy config dir (default: /etc/privoxy/)
CONFDIR=/etc/privoxy
# User-agent to use when downloading lists
USERAGENT='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:10.0.2) Gecko/20100101'
# directory for temporary files
TMPDIR=/tmp/privoxy-blocklist
TMPNAME=$(basename ${0})

######################################################################
#
#                  No changes needed after this line.
#
######################################################################

function usage()
{
	echo "${TMPNAME} is a script to convert AdBlockPlus-lists into Privoxy-lists and install them."
	echo " "
	echo "Options:"
	echo "      -h:    Show this help."
	echo "      -q:    Don't give any output."
	echo "      -v 1:  Enable verbosity 1. Show a little bit more output."
	echo "      -v 2:  Enable verbosity 2. Show a lot more output."
	echo "      -v 3:  Enable verbosity 3. Show all possible output and don't delete temporary files.(For debugging only!!)"
	echo "      -r:    Remove all lists build by this script."
}

[ ${UID} -ne 0 ] && echo -e "Root privileges needed. Exit.\n\n" && usage && exit 1

# check whether an instance is already running
[ -e ${TMPDIR}/${TMPNAME}.lock ] && echo "An Instance of ${TMPNAME} is already running. Exit" && exit

DBG=0

function debug()
{
	[ ${DBG} -ge ${2} ] && echo -e "${1}"
}

function main()
{
	cpoptions=""
	[ ${DBG} -gt 0 ] && cpoptions="-v"

	for url in ${URLS[@]}
	do
		debug "Processing ${url} ...\n" 0
		file=${TMPDIR}/$(basename ${url})
		actionfile=${file%\.*}.script.action
		filterfile=${file%\.*}.script.filter
		list=$(basename ${file%\.*})
	
		# download list
		debug "Downloading ${url} ..." 0
		wget -t 3 --no-check-certificate --user-agent="$USERAGENT" -O ${file} ${url} >${TMPDIR}/wget-${url//\//#}.log 2>&1
		debug "$(cat ${TMPDIR}/wget-${url//\//#}.log)" 2
		debug ".. downloading done." 0
		[ "$(grep -E '^\[Adblock.*\]' ${file})" == "" ] && echo "The list recieved from ${url} isn't an AdblockPlus list. Skipped" && continue
	
		# convert AdblockPlus list to Privoxy list
		# blacklist of urls
		debug "Creating actionfile for ${list} ..." 1
		echo -e "{ +block{${list}} }" > ${actionfile}
		sed '/^!.*/d;1,1 d;/^@@.*/d;/\$.*/d;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
		debug "... creating filterfile for ${list} ..." 1
		echo "FILTER: ${list} Tag filter of ${list}" > ${filterfile}
		# set filter for html elements
		sed '/^#/!d;s/^##//g;s/^#\(.*\)\[.*\]\[.*\]*/s|<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>||g/g;s/^#\(.*\)/s|<([a-zA-Z0-9]+)\\s+.*id=.?\1.*>.*<\/\\1>||g/g;s/^\.\(.*\)/s|<([a-zA-Z0-9]+)\\s+.*class=.?\1.*>.*<\/\\1>||g/g;s/^a\[\(.*\)\]/s|<a.*\1.*>.*<\/a>||g/g;s/^\([a-zA-Z0-9]*\)\.\(.*\)\[.*\]\[.*\]*/s|<\1.*class=.?\2.*>.*<\/\1>||g/g;s/^\([a-zA-Z0-9]*\)#\(.*\):.*[:[^:]]*[^:]*/s|<\1.*id=.?\2.*>.*<\/\1>||g/g;s/^\([a-zA-Z0-9]*\)#\(.*\)/s|<\1.*id=.?\2.*>.*<\/\1>||g/g;s/^\[\([a-zA-Z]*\).=\(.*\)\]/s|\1^=\2>||g/g;s/\^/[\/\&:\?=_]/g;s/\.\([a-zA-Z0-9]\)/\\.\1/g' ${file} >> ${filterfile}
		debug "... filterfile created - adding filterfile to actionfile ..." 1
		echo "{ +filter{${list}} }" >> ${actionfile}
		echo "*" >> ${actionfile}
		debug "... filterfile added ..." 1
		debug "... creating and adding whitlist for urls ..." 1
		# whitelist of urls
		echo "{ -block }" >> ${actionfile}
		sed '/^@@.*/!d;s/^@@//g;/\$.*/d;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
		debug "... created and added whitelist - creating and adding image handler ..." 1
		# whitelist of image urls
		echo "{ -block +handle-as-image }" >> ${actionfile}
		sed '/^@@.*/!d;s/^@@//g;/\$.*image.*/!d;s/\$.*image.*//g;/#/d;s/\./\\./g;s/\?/\\?/g;s/\*/.*/g;s/(/\\(/g;s/)/\\)/g;s/\[/\\[/g;s/\]/\\]/g;s/\^/[\/\&:\?=_]/g;s/^||/\./g;s/^|/^/g;s/|$/\$/g;/|/d' ${file} >> ${actionfile}
		debug "... created and added image handler ..." 1
		debug "... created actionfile for ${list}." 1
	
		# install Privoxy actionsfile
		cp ${cpoptions} ${actionfile} ${CONFDIR}
		if [ "$(grep $(basename ${actionfile}) ${CONFDIR}/config)" == "" ] 
		then
			debug "\nModifying ${CONFDIR}/config ..." 0
			sed "s/^actionsfile user\.action/actionsfile $(basename ${actionfile})\nactionsfile user.action/" ${CONFDIR}/config > ${TMPDIR}/config
			debug "... modification done.\n" 0
			debug "Installing new config ..." 0
			cp ${cpoptions} ${TMPDIR}/config ${CONFDIR}
			debug "... installation done\n" 0
		fi	
		# install Privoxy filterfile
		cp ${cpoptions} ${filterfile} ${CONFDIR}
		if [ "$(grep $(basename ${filterfile}) ${CONFDIR}/config)" == "" ] 
		then
			debug "\nModifying ${CONFDIR}/config ..." 0
			sed "s/^\(#*\)filterfile user\.filter/filterfile $(basename ${filterfile})\n\1filterfile user.filter/" ${CONFDIR}/config > ${TMPDIR}/config
			debug "... modification done.\n" 0
			debug "Installing new config ..." 0
			cp ${cpoptions} ${TMPDIR}/config ${CONFDIR}
			debug "... installation done\n" 0
		fi	
	
		debug "... ${url} installed successfully.\n" 0
	done
}

# create temporary directory and lock file
mkdir -p ${TMPDIR}
touch ${TMPDIR}/${TMPNAME}.lock

# set command to be run on exit
[ ${DBG} -le 2 ] && trap "rm -fr ${TMPDIR};exit" INT TERM EXIT

# loop for options
while getopts ":hrqv:" opt
do
	case "${opt}" in 
		"h")
			usage
			exit 0
			;;
		"v")
			DBG="${OPTARG}"
			;;
		"q")
			DBG=-1
			;;
		"r")
			echo "Do you really want to remove all build lists?(y/N)"
			read choice
			[ "${choice}" != "y" ] && exit 0
			rm -rf ${CONFDIR}/*.script.{action,filter} && \
			sed '/^actionsfile .*\.script\.action$/d;/^filterfile .*\.script\.filter$/d' -i ${CONFDIR}/config && \
			echo "Lists removed." && exit 0
			echo -e "An error occured while removing the lists.\nPlease have a look into ${CONFDIR} whether there are .script.* files and search for *.script.* in ${CONFDIR}/config."
			exit 1
			;;
		":")
			echo "${TMPNAME}: -${OPTARG} requires an argument" >&2
			exit 1
			;;
	esac
done

debug "URL-List: ${URLS}\nPrivoxy-Configdir: ${CONFDIR}\nTemporary directory: ${TMPDIR}" 2
main

# restore default exit command
trap - INT TERM EXIT
[ ${DBG} -lt 2 ] && rm -r ${TMPDIR}
[ ${DBG} -eq 2 ] && rm -vr ${TMPDIR}
exit 0
