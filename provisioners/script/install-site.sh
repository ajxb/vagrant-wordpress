#!/bin/bash

abort() {
  local error_message
  error_message="$1"

  echo "[FATAL] ${error_message}" >&2
  exit 1
}

START_TIME=$(date +"%s")

###############################################################################
# install-site.sh
#
# This script will install a Wordpress site from a production backup.
# Note that it assumes that this is a newly provisioned machine with a clean
# database and no existing wordpress installation.
###############################################################################

# Get the path to this script
MY_PATH=$(dirname "$0")
MY_PATH=$(cd "${MY_PATH}" && pwd)

DB_FILENAME=database.sql
DB_GZIP_FILENAME=$DB_FILENAME.gz
DATABASE_NAME=wordpress
FQDN=$(hostname -f | tr -d ' ')
SITE_FILENAME=site.tgz
ROOT_DIR=/vagrant
TMP_DIR=$ROOT_DIR/tmp
TMP_SITE_DIR=$TMP_DIR/site
PROVISIONERS_DIR=$ROOT_DIR/provisioners
PACKAGES_DIR=$PROVISIONERS_DIR/packages
TOOLS_DIR=$PROVISIONERS_DIR/tools
WWW_DIR=$ROOT_DIR/www

# Process any command line options passed in
while getopts ":" option; do
  case "${option}" in
    *)
      echo "Usage: install-site.sh"
      ;;
  esac
done

pushd $ROOT_DIR || abort "${ROOT_DIR} does not exist"

# Clean and recreate www folder
if [[ -d "${WWW_DIR}" ]]; then
  echo "Removing files from ${WWW_DIR}"
  rm -fr "${WWW_DIR:?}/"*
fi

# Clean and recreate tmp working folder
if [[ -d "${TMP_DIR}" ]]; then
  rm -fr "${TMP_DIR}"
fi
mkdir "${TMP_DIR}"

###############################################################################
# Install the database
###############################################################################
pushd $TMP_DIR || abort "${TMP_DIR} does not exist"

# Get the database backup
if [[ -f "${PACKAGES_DIR}/${DB_GZIP_FILENAME}" ]]; then
  echo "Copying ${PACKAGES_DIR}/${DB_GZIP_FILENAME} to ${PWD}"

  if ! cp "${PACKAGES_DIR}/${DB_GZIP_FILENAME}" .; then
    abort "Copy of ${PACKAGES_DIR}/${DB_GZIP_FILENAME} to ${PWD} failed"
  fi
else
  abort "${DB_GZIP_FILENAME} missing from ${PACKAGES_DIR}, ensure backup files exist prior to running this script"
fi

# Extract out the database
echo "Unziping ${DB_GZIP_FILENAME}"
if ! gunzip "${DB_GZIP_FILENAME}"; then
  abort "Unzip of ${DB_GZIP_FILENAME} failed"
fi

# Import the database
echo "Importing ${DB_FILENAME} into mysql database ${DATABASE_NAME}"
if ! mysql "${DATABASE_NAME}" < "${DB_FILENAME}"; then
  abort "Import of ${DB_FILENAME} into mysql database ${DATABASE_NAME} failed"
fi

URL=$(mysql -uwordpress -pwordpress -e 'SELECT option_value FROM clblog_options WHERE option_name = "siteurl"' "${DATABASE_NAME}" -ss)
DB_STRINGS_TO_REPLACE=("${URL}")

# Update the database for the development machine
REPLACEMENT_STR="http://${FQDN}"
echo "Updating ${DATABASE_NAME} URL entries to point to ${FQDN}"
for STR in "${DB_STRINGS_TO_REPLACE[@]}"; do
  echo
  echo "Replacing ${STR} with ${REPLACEMENT_STR} in ${DATABASE_NAME} mysql database"
  "${TOOLS_DIR}/Search-Replace-DB/srdb.cli.php" --host localhost --name $DATABASE_NAME --user wordpress --pass wordpress --search "${STR}" --replace "${REPLACEMENT_STR}"
done

popd || abort "popd failed" # /vagrant/tmp

###############################################################################
# Install the website
###############################################################################
pushd $TMP_DIR || abort "${TMP_DIR} does not exist"

# Get the website backup
if [[ -f "${PACKAGES_DIR}/${SITE_FILENAME}" ]]; then
  echo "Copying ${PACKAGES_DIR}/${SITE_FILENAME} to ${PWD}"
  if ! cp "${PACKAGES_DIR}/${SITE_FILENAME}" .; then
    abort "Copy of ${PACKAGES_DIR}/${SITE_FILENAME} to ${PWD} failed"
  fi
else
  abort "${SITE_FILENAME} missing from ${PACKAGES_DIR}, ensure backup files exist prior to running this script"
fi

# Extract out the website (we just need the public_html folder)
echo "Extracting site from ${SITE_FILENAME}"
if ! tar xfz "${SITE_FILENAME}"; then
  abort "Extraction of site from ${SITE_FILENAME} failed"
fi

pushd $TMP_SITE_DIR || abort "${TMP_SITE_DIR} does not exist"

echo "Removing files that aren't required for installation"
rm -f "$(find ./ -name "error_log")"
rm -f "$(find ./ -name "*.orig")"
rm -f "$(find ./ -name "*.old")"
rm -f "$(find ./ -name "*.bak")"
rm -f "sitemap.xml"
rm -f "sitemap.xml.gz"

# Update robots.txt
echo 'Updating robots.txt'
#if ! sed -i -r "s/http[s]?:\/\/[[:alnum:]\.-]*/http:\/\/${FQDN}/g" robots.txt; then
if ! sed -i -r "s/http[s]?:\\/\\/[[:alnum:]\\.-]*/http:\\/\\/${FQDN}/g" robots.txt; then
  abort 'Update of robots.txt failed'
fi

# Update .htaccess
echo 'Updating .htaccess'
if ! cp -f "${PROVISIONERS_DIR}/script/files/.htaccess" .; then
  abort 'Update of .htaccess failed'
fi

# Removing any customised php.ini file
if [[ -f php.ini ]]; then
  echo 'Removing php.ini'
  rm "php.ini"
fi

# Move the site into the www folder
echo "Moving site files to ${WWW_DIR}"
shopt -s dotglob
mv ./* "${WWW_DIR}/"

popd || abort 'popd failed' # /vagrant/tmp/$TMP_SITE_DIR
popd || abort 'popd failed' # /vagrant/tmp
popd || abort 'popd failed' # /vagrant

# Clean tmp working folder
if [[ -d "${TMP_DIR}" ]]; then
 rm -fr "${TMP_DIR}"
fi

END_TIME=$(date +"%s")
TIME_TAKEN=$((END_TIME-START_TIME))

echo "$((TIME_TAKEN / 60)) minutes and $((TIME_TAKEN % 60)) seconds elapsed."
