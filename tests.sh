#!/bin/bash
set -euo pipefail

# Extract version to build from the repo
DEBVERSION=$(grep Version debian/control | awk -F': ' '{print $2}')
DEBARCH=$(grep Architecture debian/control | awk -F': ' '{print $2}')
DEBFILE="deb/thelounge_${DEBVERSION}_${DEBARCH}.deb"
NPMVERSION=$(echo "${DEBVERSION}" | sed -E 's/-[0-9]+$//' | sed -E 's/~/-/')

# Exit status code to update if there is a failure
CODE=0

echo
echo "$DEBFILE"

# The deb file should correctly exist
if [ -e "$DEBFILE" ]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mwas correctly built\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ was not built\\x1B[0m"
  CODE=1
fi

# The file should have a minimum size for safety (ensures we did not create an
# empty file), and a maximum size (ensures we did not load way too much
# third-party code.
if [ -e "$DEBFILE" ]; then
  FILESIZE=$(ls -l "$DEBFILE" | awk '{print $5}')
  HUMANSIZE=$(ls -lh "$DEBFILE" | awk '{print $5}')
  MINSIZE=3
  MAXSIZE=10

  if [ "$FILESIZE" -gt "$((MINSIZE * 1024 * 1024))" ] &&
     [ "$FILESIZE" -lt "$((MAXSIZE * 1024 * 1024))" ]; then
    echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mhas a valid file size ($HUMANSIZE)\\x1B[0m"
  else
    echo -e "  \\x1B[31m✗ has an invalid file size\\x1B[0m"
    echo -e "      \\x1B[32mminimum: ${MINSIZE}M\\x1B[0m"
    echo -e "      \\x1B[32mmaximum: ${MAXSIZE}M\\x1B[0m"
    echo -e "      \\x1B[31mactual:  ${HUMANSIZE}\\x1B[0m"
    echo
    CODE=1
  fi
else
  echo -e "  \\x1B[36m- file size could not be checked\\x1B[0m"
fi

# sqlite should be installed correctly at runtime
if [ -e "/usr/lib/node_modules/thelounge/node_modules/sqlite3/package.json" ]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90msqlite was installed correctly at runtime\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ sqlite was not installed at runtime\\x1B[0m"
  CODE=1
fi

# sqlite binding should be installed correctly at runtime
if [ "$(ls -A /usr/lib/node_modules/thelounge/node_modules/sqlite3/lib/binding/)" ]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90msqlite binding exists\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ sqlite binding does not exist\\x1B[0m"
  CODE=1
fi

# If the service was correctly set up with systemd, it should show in the big
# `sudo systemctl` list.
SYSTEMCTL_LIST=$(sudo systemctl | grep "thelounge.service")
if [[ "$SYSTEMCTL_LIST" = *"The Lounge (IRC client)"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mcorrectly shows up in systemctl list\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ was not found or incorrectly listed\\x1B[0m"
  echo -e "      \\x1B[32mexpected: The Lounge (IRC client)\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_LIST}\\x1B[0m"
  echo
  CODE=1
fi

# Wait until The Lounge is actually fully started
sleep 2

# Entire entry for the service. We'll use this to see if everything is in order.
SYSTEMCTL_STATUS=$(sudo systemctl status --full thelounge.service)

# `systemctl status` should report `Active: active (running) since ...`
SYSTEMCTL_ACTIVE=$(echo "${SYSTEMCTL_STATUS}" | grep "Active:")
if [[ "$SYSTEMCTL_ACTIVE" = *"active (running)"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mis reported as active and running by systemctl status\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not have a status of active and running\\x1B[0m"
  echo -e "      \\x1B[32mexpected: Active: active (running)\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_ACTIVE}\\x1B[0m"
  echo
  CODE=1
fi

SYSTEMCTL_STARTED=$(echo "${SYSTEMCTL_STATUS}" | grep "systemd\\[")
if [[ "$SYSTEMCTL_STARTED" = *"Started The Lounge (IRC client)"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mshows up as started in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not show up as started in systemctl\\x1B[0m"
  echo -e "      \\x1B[32mexpected: Started The Lounge (IRC client)\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_STARTED}\\x1B[0m"
  echo
  CODE=1
fi

SYSTEMCTL_VERSION=$(echo "${SYSTEMCTL_STATUS}" | grep "The Lounge v")
if [[ "$SYSTEMCTL_VERSION" = *"$NPMVERSION"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mshows correct version in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not show up correct version in systemctl\\x1B[0m"
  echo -e "      \\x1B[32mexpected: The Lounge v$NPMVERSION\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_VERSION}\\x1B[0m"
  echo
  CODE=1
fi

SYSTEMCTL_CONFIG=$(echo "${SYSTEMCTL_STATUS}" | grep "Configuration file:")
if [[ "$SYSTEMCTL_CONFIG" = *"/etc/thelounge/config.js"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mshows correct configuration path in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not show up correct version in systemctl logs\\x1B[0m"
  echo -e "      \\x1B[32mexpected: Configuration file: /etc/thelounge/config.js\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_CONFIG}\\x1B[0m"
  echo
  CODE=1
fi

SYSTEMCTL_URL=$(echo "${SYSTEMCTL_STATUS}" | grep "Available at")
if [[ "$SYSTEMCTL_URL" = *"http://[::]:9000/"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mshows correct URL in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not show up correct URL in systemctl logs\\x1B[0m"
  echo -e "      \\x1B[32mexpected: Available at http://[::]:9000/\\x1B[0m"
  echo -e "      \\x1B[31mactual:   ${SYSTEMCTL_URL}\\x1B[0m"
  echo
  CODE=1
fi

SYSTEMCTL_LOGS=$(echo "${SYSTEMCTL_STATUS}" | grep "thelounge\\[")

if [[ "$SYSTEMCTL_LOGS" != *"[WARN]"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mdoes not have any warnings in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ has warnings in systemctl in systemctl logs\\x1B[0m"
  echo -e "      \\x1B[31mactual:   $(echo "${SYSTEMCTL_LOGS}" | grep "\\[WARN\\]")\\x1B[0m"
  echo
  CODE=1
fi

if [[ "$SYSTEMCTL_LOGS" != *"[ERROR]"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mdoes not have any errors in systemctl logs\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ has errors in systemctl in systemctl logs\\x1B[0m"
  echo -e "      \\x1B[31mactual:   $(echo "${SYSTEMCTL_LOGS}" | grep "\\[ERROR\\]")\\x1B[0m"
  echo
  CODE=1
fi

THELOUNGE_HTML=$(curl --silent http://localhost:9000)
if [[ "$THELOUNGE_HTML" = *"<title>The Lounge</title>"* ]]; then
  echo -e "  \\x1B[32m✓\\x1B[0m \\x1B[90mreturns correct HTML markup when calling the webserver\\x1B[0m"
else
  echo -e "  \\x1B[31m✗ does not return correct HTML markup when calling the webserver\\x1B[0m"
  echo -e "      \\x1B[32mexpected: <title>The Lounge</title>\\x1B[0m"
  echo -e "      \\x1B[31mactual:\\x1B[0m"
  echo "$THELOUNGE_HTML"
  CODE=1
fi

exit $CODE
