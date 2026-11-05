#!/usr/bin/env bash
set -euo pipefail

release_tag="${1:-}"

if [[ ! "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "release tag must be semantic versioning prefixed with v: $release_tag" >&2
  exit 1
fi

release_version="${release_tag#v}"
manifest_version="$(jq -r '.version' nox.json)"
source_version="$(sed -n 's/^OBSIDIAN_VERSION: str = "\([^"]*\)"$/\1/p' version.nox)"

if [ "$manifest_version" != "$release_version" ]; then
  echo "tag $release_tag does not match nox.json version $manifest_version" >&2
  exit 1
fi

if [ "$source_version" != "$release_version" ]; then
  echo "tag $release_tag does not match version.nox version $source_version" >&2
  exit 1
fi

if ! grep -q "^## \[$release_version\]" CHANGELOG.md; then
  echo "CHANGELOG.md has no release section for $release_version" >&2
  exit 1
fi

if grep -q "not licensed for redistribution" LICENSE; then
  echo "a redistribution license must be selected before publishing" >&2
  exit 1
fi

if [ "$(git rev-list -n 1 "$release_tag")" != "$(git rev-parse HEAD)" ]; then
  echo "release tag does not point at the checked-out commit" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "release checkout is not clean" >&2
  exit 1
fi

printf 'release preflight passed: %s\n' "$release_tag"
