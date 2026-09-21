#!/usr/bin/env bash
# Source this file in an interactive shell after `npm run setup`.
# It leaves explicit -C/--cd or -p/--profile invocations untouched.

codex() {
  local codex_bin root profile arg next_is_cd=0 next_is_profile=0 next_is_feature=0
  local has_explicit_workspace_or_profile=0 has_shell_snapshot_choice=0

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    codex_bin="$(whence -p codex)"
  else
    codex_bin="$(type -P codex)"
  fi
  [[ -n "$codex_bin" ]] || {
    printf '%s\n' 'error: codex executable was not found on PATH' >&2
    return 127
  }
  root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || {
    command "$codex_bin" "$@"
    return
  }
  [[ -r "$root/.codex/profile-name" ]] || {
    command "$codex_bin" "$@"
    return
  }
  IFS= read -r profile < "$root/.codex/profile-name"
  [[ "$profile" =~ ^[A-Za-z0-9_-]+$ ]] || {
    command "$codex_bin" "$@"
    return
  }

  for arg in "$@"; do
    if (( next_is_cd || next_is_profile )); then
      has_explicit_workspace_or_profile=1
      next_is_cd=0; next_is_profile=0
      continue
    fi
    if (( next_is_feature )); then
      [[ "$arg" == shell_snapshot ]] && has_shell_snapshot_choice=1
      next_is_feature=0
      continue
    fi
    case "$arg" in
      -C|--cd) next_is_cd=1 ;;
      -C*|--cd=*) has_explicit_workspace_or_profile=1 ;;
      -p|--profile) next_is_profile=1 ;;
      -p?*|--profile=*) has_explicit_workspace_or_profile=1 ;;
      --disable|--enable) next_is_feature=1 ;;
      --disable=shell_snapshot|--enable=shell_snapshot) has_shell_snapshot_choice=1 ;;
    esac
  done

  if (( has_explicit_workspace_or_profile )); then
    command "$codex_bin" "$@"
  elif (( has_shell_snapshot_choice )); then
    command "$codex_bin" -C "$root" -p "$profile" "$@"
  else
    command "$codex_bin" -C "$root" -p "$profile" --disable shell_snapshot "$@"
  fi
}
