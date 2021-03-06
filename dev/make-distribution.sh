#!/usr/bin/env bash
##############################################################
#
# File: make-distribution.sh
#
# Description: creates files and arcchives to distribute bashbot
#
# Options: --notest - skip tests
#
#### $$VERSION$$ v1.21-0-gc85af77
##############################################################

# magic to ensure that we're always inside the root of our application,
# no matter from which directory we'll run script
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR" != "" ] ; then
	[[ "$GIT_DIR" != "/"* ]] && GIT_DIR="${PWD}/${GIT_DIR}"
	cd "$GIT_DIR/.." || exit 1
else
	printf "Sorry, no git repository %s\n" "$(pwd)" && exit 1
fi

VERSION="$(git describe --tags | sed -e 's/-[0-9].*//' -e 's/v//')"

DISTNAME="telegram-bot-bash"
DISTDIR="./DIST/${DISTNAME}" 
DISTFILES="bashbot.rc bashbot.sh commands.sh mycommands.sh mycommands.sh.clean bin doc examples scripts modules addons LICENSE README.md README.txt README.html"
DISTMKDIR="data-bot-bash logs bin bin/logs"

# run tests first!
for test in $1 dev/all-test*.sh
do
   [[ "${test}" == "--notest"* ]] && break
   [ ! -x "${test}" ] && continue
   if ! "${test}" ; then
	printf "ERROR: Test %s failed, can't create dist!\n" "${test}"
	exit 1
  fi
done

# create dir for distribution and copy files
mkdir -p "${DISTDIR}" 2>/dev/null

printf "Copy files\n"
# shellcheck disable=SC2086
cp -r ${DISTFILES} "${DISTDIR}"
cd "${DISTDIR}" || exit 1

printf "Create directories\n"
for dir in $DISTMKDIR
do
	[ ! -d "${dir}" ] && mkdir "${dir}"
done

# do not overwrite on update
printf "Create .dist files\n"
for file in mycommands.sh bashbot.rc addons/*.sh
do
	[ "${file}" = "addons/*.sh" ] && continue
	mv "${file}" "${file}.dist"
done

# inject JSON.sh into distribution
# shellcheck disable=SC1090
source "$GIT_DIR/../dev/inject-json.sh"

# make html doc
printf "Create html doc\n"
# shellcheck disable=SC1090,SC1091
source "../../dev/make-html.sh"

# create archive
cd .. || exit 1
printf "Create dist archives\n"
# shellcheck disable=SC2046
zip -rq - "${DISTNAME}" --exclude $(cat  "$GIT_DIR/../dev/${0##*/}.exclude") >"${DISTNAME}-${VERSION}.zip"
tar --exclude-ignore="$GIT_DIR/../dev/${0##*/}.exclude" -czf "${DISTNAME}-${VERSION}.tar.gz" "${DISTNAME}"

printf "%s Done!\n" "$0"

# shellcheck disable=SC2086
ls -ld ${DISTNAME}-${VERSION}.*

# an empty DEBUG.log is created ... :-(
rm -f "$GIT_DIR/../test/"*.log
