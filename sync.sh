#!/bin/sh

set -e

cp ./README.md ./public/README.md
cd ./public

for db in GeoLite2-ASN GeoLite2-City GeoLite2-Country; do
  wget -q -O "./${db}.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=${db}&license_key=${LICENSE_KEY}&suffix=tar.gz"
  tar xzf "./${db}.tar.gz" -C .
  wget -q -O "./${db}-CSV.zip" "https://download.maxmind.com/app/geoip_download?edition_id=${db}-CSV&license_key=${LICENSE_KEY}&suffix=zip"
done

VERSION=$(ls | grep 'GeoLite2-Country_' | sed "s|GeoLite2-Country_||g" | tr -d '\n')
DATE="$(echo $(TZ=UTC-8 date '+%Y--%m--%d%%20%H%%3A%M%%3A%S'))"

cp ./GeoLite2-Country_*/GeoLite2-Country.mmdb ./
cp ./GeoLite2-Country_*/GeoLite2-Country.mmdb ./Country.mmdb
cp ./GeoLite2-ASN_*/GeoLite2-ASN.mmdb ./
cp ./GeoLite2-ASN_*/GeoLite2-ASN.mmdb ./ASN.mmdb
cp ./GeoLite2-City_*/GeoLite2-City.mmdb ./
cp ./GeoLite2-City_*/GeoLite2-City.mmdb ./City.mmdb
rm -rf ./GeoLite2-*_*

echo $VERSION >version

sed -i "s|## Sync Status|## Sync Status\n\n![](https://img.shields.io/badge/Version-$VERSION-2f8bff.svg)\n![](https://img.shields.io/badge/Last%20Sync-$DATE-blue.svg)|g" README.md

cd ..

# Deploy

mkdir ./public-git
cd ./public-git
git init
git config --global push.default matching
git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"
git remote add origin https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/1mr/geolite-mirror.git
git checkout -b gh-pages
cp -rf ../public/* ./

# generate download.md
printf "#\n\n" >download.md
printf "## Sync Status\n\n" >>download.md
printf "[![Sync CI](https://github.com/1mr/geolite-mirror/actions/workflows/sync.yml/badge.svg)](https://github.com/1mr/geolite-mirror/actions/workflows/sync.yml)\n\n" >>download.md
printf "## Download\n\n" >>download.md

for f in *.mmdb; do
  printf "\`\`\`plain\n" >>download.md
  printf "https://geolite2.1mr.me/${f}\n" >>download.md
  printf "\`\`\`\n\n" >>download.md
done
for f in *-csv.zip; do
  printf "\`\`\`plain\n" >>download.md
  printf "https://geolite2.1mr.me/${f}\n" >>download.md
  printf "\`\`\`\n\n" >>download.md
done

git add --all .
DATE="$(echo $(TZ=UTC-8 date '+%Y-%m-%d %H:%M:%S'))"
git commit -m "Synced success at $DATE - $VERSION"
git push --quiet --force origin HEAD:gh-pages
