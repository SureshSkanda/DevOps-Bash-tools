#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-07 07:20:10 +0400 (Thu, 07 Nov 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Uploads a file to https://file.io/ and copies the resulting URL to your clipboard

If the content is ASCII then prompts to confirm the content before uploading for your safe review as this is PUBLIC

Does not do this for non-ASCII files since we can't print media content to the terminal

Retention is a single download by design only and up to 2 weeks availability

Recommended: for text use anonymize.py or anonymize.pl from the adjacent DevOps-Python-tools or DevOps-Perl-tools repos

Optional: for code - decomment.sh

Knowledge Base page: https://github.com/HariSekhon/Knowledge-Base/blob/main/upload-sites.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

min_args 1 "$@"

IMGUR_CLIENT_ID="${IMGUR_CLIENT_ID:-DevOps-Bash-tools}"

url="https://api.imgur.com/3/image"
file="$1"

# Do not allow reading from stdin because it does not allow the prompt safety
#if [ "$file" = '-' ]; then
#    timestamp "reading from stdin"
    #file="/dev/stdin"
#else
#    timestamp "reading from file: $file"
#fi

if ! file "$file" | grep -qi image; then
    die "Only image files may be uploaded"
fi

result="$(
    command curl -sSl "$url" \
             -H "Authorization: Client-ID $IMGUR_CLIENT_ID" \
             -F "image=@$file"
)"

jq_debug_pipe_dump <<< "$result" > /dev/null

success="$(jq -r .success <<< "$result")"
if [ "$success" != true ]; then
    error="$(jq -r .data.error <<< "$result")"
    die "ERROR: $error"
fi

jq -r '.data.link' <<< "$result" |
tee /dev/stderr |
"$srcdir/copy_to_clipboard.sh"