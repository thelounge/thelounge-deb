#!/bin/bash
set -e

# Extract version to build from the repo
DEBFILE="deb/lounge_`grep Version debian/control | awk -F': ' '{print $2}'`_all.deb"

# Exit status code to update if there is a failure
CODE=0

echo
echo $DEBFILE

# The deb file should correctly exist
if [ -e "$DEBFILE" ]; then
  echo -e "  \x1B[32m✓\x1B[0m \x1B[90mwas correctly built\x1B[0m"
else
  echo -e "  \x1B[31m✗ was not built\x1B[0m"
  CODE=1
fi

# The file should have a minimum size for safety (ensures we did not create an
# empty file), and a maximum size (ensures we did not load way too much
# third-party code.
if [ -e "$DEBFILE" ]; then
  FILESIZE=`ls -l $DEBFILE | awk '{print $5}'`
  HUMANSIZE=`ls -lh $DEBFILE | awk '{print $5}'`
  MINSIZE=3
  MAXSIZE=10

  if [ "$FILESIZE" -gt "$(($MINSIZE * 1024 * 1024))" ] &&
     [ "$FILESIZE" -lt "$(($MAXSIZE * 1024 * 1024))" ]; then
    echo -e "  \x1B[32m✓\x1B[0m \x1B[90mhas a valid file size ($HUMANSIZE)\x1B[0m"
  else
    echo -e "  \x1B[31m✗ has an invalid file size\x1B[0m"
    echo -e "      \x1B[32mminimum: ${MINSIZE}M\x1B[0m"
    echo -e "      \x1B[32mmaximum: ${MAXSIZE}M\x1B[0m"
    echo -e "      \x1B[31mactual:  ${HUMANSIZE}\x1B[0m"
    CODE=1
  fi
else
  echo -e "  \x1B[36m- file size could not be checked\x1B[0m"
fi

exit $CODE
