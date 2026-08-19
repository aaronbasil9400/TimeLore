#!/usr/bin/env bash
set -euo pipefail

old_name="${OLD_NAME:-TimeLore}"
new_name="${1:-}"

if [[ -z "$new_name" ]]; then
  echo "Usage: OLD_NAME=$old_name $0 NewName" >&2
  exit 2
fi

if [[ ! "$new_name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
  echo "NewName must be an alphanumeric Swift/Xcode name beginning with a letter." >&2
  exit 2
fi

if [[ "$old_name" == "$new_name" ]]; then
  echo "The new name is already active." >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

for required in "$old_name.xcodeproj" "$old_name" "${old_name}Tests" "${old_name}UITests"; do
  if [[ ! -e "$required" ]]; then
    echo "Expected path not found: $required" >&2
    exit 1
  fi
done

# Rename paths first so the Xcode project and scheme remain discoverable.
git mv "$old_name.xcodeproj" "$new_name.xcodeproj"
git mv "$old_name" "$new_name"
git mv "${old_name}Tests" "${new_name}Tests"
git mv "${old_name}UITests" "${new_name}UITests"

if [[ -e "$new_name/${old_name}App.swift" ]]; then
  git mv "$new_name/${old_name}App.swift" "$new_name/${new_name}App.swift"
fi

if [[ -e "$new_name/Resources/Assets.xcassets/AppIcon.appiconset/${old_name}AppIcon.png" ]]; then
  git mv "$new_name/Resources/Assets.xcassets/AppIcon.appiconset/${old_name}AppIcon.png" \
    "$new_name/Resources/Assets.xcassets/AppIcon.appiconset/${new_name}AppIcon.png"
fi

if [[ -e "$new_nameUITests/${old_name}UITests.swift" ]]; then
  git mv "$new_nameUITests/${old_name}UITests.swift" "$new_nameUITests/${new_name}UITests.swift"
fi

# Update text references, excluding Git metadata and generated build output.
while IFS= read -r file; do
  perl -0pi -e "s/\Q$old_name\E/$new_name/g" "$file"
done < <(git grep -Il "$old_name" -- ':!*.xcuserstate' ':!DerivedData' || true)

echo "Renamed $old_name to $new_name."
echo "Review the diff, then build and test the renamed shared scheme before committing."
