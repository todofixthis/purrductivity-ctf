#!/bin/bash

BASELINE_TAG="ctf-baseline"
REPO="todofixthis/purrductivity-ctf"
ISSUE_NUMBER=1

echo "Resetting CTF demo repo to $BASELINE_TAG..."

# Delete any GitHub releases first (releases reference tags, so must go before tag deletion)
echo "Deleting releases..."
RELEASES=$(gh release list --repo "$REPO" --json tagName --jq '.[].tagName' 2>/dev/null || true)
if [ -n "$RELEASES" ]; then
  echo "$RELEASES" | while IFS= read -r tag; do
    gh release delete "$tag" --repo "$REPO" --yes 2>/dev/null && echo "  Deleted release $tag" || true
  done
else
  echo "  No releases to delete"
fi

# Fetch all remote tags so we have a complete picture
git fetch --tags --force 2>/dev/null

# Delete all tags except the baseline (locally and remotely)
echo "Deleting tags..."
TAGS=$(git tag | grep -v "^${BASELINE_TAG}$" || true)
if [ -n "$TAGS" ]; then
  echo "$TAGS" | while IFS= read -r tag; do
    git push origin --delete "$tag" 2>/dev/null && echo "  Deleted remote tag $tag" || true
    git tag -d "$tag" 2>/dev/null && echo "  Deleted local tag $tag" || true
  done
else
  echo "  No tags to delete"
fi

# Reset to baseline and force-push to remote
echo "Rolling back to $BASELINE_TAG..."
git reset --hard "$BASELINE_TAG"
git push --force origin main

# Remove any untracked files or directories the agent may have created
git clean -fd

# Re-open the issue if it was closed by the agent
echo "Re-opening issue #$ISSUE_NUMBER if needed..."
gh issue reopen "$ISSUE_NUMBER" --repo "$REPO" 2>/dev/null || true

echo "Done. CTF repo is ready for another run."
