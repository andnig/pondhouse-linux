#!/bin/bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  echo "not ok - $1" >&2
  exit 1
}

pass() {
  echo "ok - $1"
}

make_shared_history() {
  local name=$1 seed shared
  seed="$TMPDIR/$name-seed"
  shared="$TMPDIR/$name-shared.git"
  git init -q --bare "$shared"
  git clone -q "$shared" "$seed"
  git -C "$seed" config user.name Test
  git -C "$seed" config user.email test@example.com
  mkdir -p "$seed/bin"
  cp "$ROOT/bin/omarchy" "$ROOT/bin/omarchy-update" "$ROOT/bin/omarchy-update-git" "$seed/bin/"
  printf '#!/bin/bash\necho old migration\n' >"$seed/bin/omarchy-pondhouse-upgrade-to-quattro"
  chmod 755 "$seed/bin"/*
  git -C "$seed" add bin
  git -C "$seed" commit -qm baseline
  git -C "$seed" branch -M master
  git -C "$seed" push -q origin master
  git --git-dir="$shared" symbolic-ref HEAD refs/heads/master
  cp "$ROOT/bin/omarchy-pondhouse-upgrade-to-quattro" \
    "$seed/bin/omarchy-pondhouse-upgrade-to-quattro"
  git -C "$seed" add bin/omarchy-pondhouse-upgrade-to-quattro
  git -C "$seed" commit -qm 'correct migration trust ordering'
  git -C "$seed" push -q origin master
  printf '%s\t%s\n' "$seed" "$shared"
}

make_update_shims() {
  local directory=$1
  mkdir -p "$directory"
  for command in hyprctl omarchy-snapshot omarchy-update-perform omarchy-update-time; do
    printf '#!/bin/bash\nexit 0\n' >"$directory/$command"
    chmod 755 "$directory/$command"
  done
}

assert_migration_command() {
  local checkout=$1
  [[ -x $checkout/bin/omarchy-pondhouse-upgrade-to-quattro ]] || fail "migration command remains executable"
  PATH="$checkout/bin:$PATH" "$checkout/bin/omarchy" pondhouse upgrade-to-quattro --help \
    >/dev/null || fail "migration command resolves through CLI"
}

IFS=$'\t' read -r seed shared < <(make_shared_history direct)
direct="$TMPDIR/direct-employee"
git clone -q "$shared" "$direct"
git -C "$direct" reset -q --hard HEAD~1
make_update_shims "$TMPDIR/direct-bin"
OMARCHY_PATH="$direct" OMARCHY_UPDATE_LOGGED=1 PATH="$TMPDIR/direct-bin:$direct/bin:$PATH" \
  "$direct/bin/omarchy-update" -y >/dev/null
[[ $(git -C "$direct" rev-parse HEAD) == $(git --git-dir="$shared" rev-parse master) ]] || \
  fail "direct checkout receives shared correction"
assert_migration_command "$direct"
pass "direct shared checkout receives the executable corrected command"

IFS=$'\t' read -r seed shared < <(make_shared_history fork)
baseline=$(git -C "$seed" rev-parse HEAD~1)
fork="$TMPDIR/personal-fork.git"
git init -q --bare "$fork"
git -C "$seed" push -q "$fork" "$baseline:refs/heads/master"
git --git-dir="$fork" symbolic-ref HEAD refs/heads/master
personal_seed="$TMPDIR/personal-seed"
git clone -q "$fork" "$personal_seed"
git -C "$personal_seed" config user.name Employee
git -C "$personal_seed" config user.email employee@example.com
printf 'employee customization\n' >"$personal_seed/employee.txt"
git -C "$personal_seed" add employee.txt
git -C "$personal_seed" commit -qm 'employee customization'
personal_commit=$(git -C "$personal_seed" rev-parse HEAD)
git -C "$personal_seed" push -q origin master

employee="$TMPDIR/personal-employee"
git clone -q "$fork" "$employee"
git -C "$employee" remote add pondhouse "$shared"
git -C "$employee" config user.name Employee
git -C "$employee" config user.email employee@example.com
make_update_shims "$TMPDIR/fork-bin"
OMARCHY_PATH="$employee" OMARCHY_UPDATE_LOGGED=1 PATH="$TMPDIR/fork-bin:$employee/bin:$PATH" \
  "$employee/bin/omarchy-update" -y >/dev/null
git -C "$employee" merge-base --is-ancestor "$personal_commit" HEAD || fail "personal commit remains present"
git -C "$employee" merge-base --is-ancestor "$(git --git-dir="$shared" rev-parse master)" HEAD || \
  fail "personal fork receives shared correction"
[[ $(git --git-dir="$fork" rev-parse master) == $(git -C "$employee" rev-parse HEAD) ]] || \
  fail "merged personal state is pushed to employee origin"
[[ $(git --git-dir="$shared" rev-parse master) != $(git -C "$employee" rev-parse HEAD) ]] || \
  fail "employee commit is not pushed to shared remote"
assert_migration_command "$employee"
pass "personal fork keeps employee commits and pushes merged state only to origin"

direct_conflict="$TMPDIR/direct-conflict"
git clone -q "$shared" "$direct_conflict"
git -C "$direct_conflict" config user.name Employee
git -C "$direct_conflict" config user.email employee@example.com
shared_direct_edit="$TMPDIR/shared-direct-edit"
git clone -q "$shared" "$shared_direct_edit"
git -C "$shared_direct_edit" config user.name Shared
git -C "$shared_direct_edit" config user.email shared@example.com
printf 'employee version\n' >"$direct_conflict/direct-conflict.txt"
git -C "$direct_conflict" add direct-conflict.txt
git -C "$direct_conflict" commit -qm 'direct employee conflict'
direct_conflict_commit=$(git -C "$direct_conflict" rev-parse HEAD)
printf 'shared version\n' >"$shared_direct_edit/direct-conflict.txt"
git -C "$shared_direct_edit" add direct-conflict.txt
git -C "$shared_direct_edit" commit -qm 'direct shared conflict'
git -C "$shared_direct_edit" push -q origin master
make_update_shims "$TMPDIR/direct-conflict-bin"
if OMARCHY_PATH="$direct_conflict" OMARCHY_UPDATE_LOGGED=1 \
  PATH="$TMPDIR/direct-conflict-bin:$direct_conflict/bin:$PATH" \
  "$direct_conflict/bin/omarchy-update" -y >"$TMPDIR/direct-conflict-output" 2>&1; then
  fail "conflicting direct update succeeds"
fi
grep -Fq 'Your local work was not reset or discarded' "$TMPDIR/direct-conflict-output" || \
  fail "direct conflict guidance is shown"
git -C "$direct_conflict" cat-file -e "$direct_conflict_commit^{commit}" || \
  fail "direct employee commit survives conflict"
pass "direct checkout conflict gives guidance without resetting employee work"

conflict_shared="$TMPDIR/conflict-shared.git"
conflict_fork="$TMPDIR/conflict-fork.git"
git clone -q --bare "$shared" "$conflict_shared"
git clone -q --bare "$fork" "$conflict_fork"
shared_edit="$TMPDIR/conflict-shared-edit"
git clone -q "$conflict_shared" "$shared_edit"
git -C "$shared_edit" config user.name Shared
git -C "$shared_edit" config user.email shared@example.com
printf 'shared version\n' >"$shared_edit/conflict.txt"
git -C "$shared_edit" add conflict.txt
git -C "$shared_edit" commit -qm 'shared conflict'
git -C "$shared_edit" push -q origin master
conflict_employee="$TMPDIR/conflict-employee"
git clone -q "$conflict_fork" "$conflict_employee"
git -C "$conflict_employee" config user.name Employee
git -C "$conflict_employee" config user.email employee@example.com
printf 'employee version\n' >"$conflict_employee/conflict.txt"
git -C "$conflict_employee" add conflict.txt
git -C "$conflict_employee" commit -qm 'employee conflict'
conflict_commit=$(git -C "$conflict_employee" rev-parse HEAD)
git -C "$conflict_employee" remote add pondhouse "$conflict_shared"
make_update_shims "$TMPDIR/conflict-bin"
if OMARCHY_PATH="$conflict_employee" OMARCHY_UPDATE_LOGGED=1 \
  PATH="$TMPDIR/conflict-bin:$conflict_employee/bin:$PATH" \
  "$conflict_employee/bin/omarchy-update" -y >"$TMPDIR/conflict-output" 2>&1; then
  fail "conflicting update succeeds"
fi
grep -Fq 'Resolve the conflicts' "$TMPDIR/conflict-output" || fail "conflict guidance is shown"
git -C "$conflict_employee" cat-file -e "$conflict_commit^{commit}" || fail "employee commit survives conflict"
[[ $(git --git-dir="$conflict_fork" rev-parse master) != $(git --git-dir="$conflict_shared" rev-parse master) ]] || \
  fail "conflict does not overwrite employee origin"
pass "conflicting update gives guidance without resetting or discarding employee work"

echo "All Pondhouse employee update layout tests passed"
