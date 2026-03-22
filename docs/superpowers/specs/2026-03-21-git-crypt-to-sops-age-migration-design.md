# git-crypt to SOPS + age Migration Design

## Summary

This repository will remove `git-crypt` entirely and standardize on `sops` with
`age` recipients for all encrypted material. The migration covers two classes of
content:

- text secrets that are currently stored as encrypted Nix files and imported at
  evaluation time
- proprietary font assets that must remain encrypted in git but must not be
  copied into `/nix/store`

The rollout will happen in two commits:

1. add the `sops`/`age` plumbing to every active system without changing the
   current encrypted files or imports
2. migrate the secrets and remove all `git-crypt` state from the repository

This ordering ensures every target host can first build a closure containing the
new decryption machinery before the repo starts depending on it.

## Goals

- Remove `.git-crypt/` and all `git-crypt` filters from the repository.
- Use a single secrets workflow based on `sops` and `age`.
- Keep API keys available in shell environments for downstream programs.
- Keep proprietary fonts encrypted in git.
- Avoid copying secret values or proprietary font payloads into the
  world-readable Nix store.
- Make the migration safe to deploy across multiple Darwin hosts with a staged
  two-commit rollout.

## Non-goals

- Changing the actual secret values as part of the migration.
- Broadly refactoring unrelated Home Manager or nix-darwin modules.
- Introducing a separate secret backend such as cloud KMS or Vault.

## Current State

The current repository relies on `git-crypt` filters from `.gitattributes` to
protect:

- `home-manager/shayne/environment.enc.nix`
- `home-manager/lib/shellAliases.enc.nix`
- `modules/ssh/default.enc.nix`
- `modules/custom-fonts.enc/**`

The current text secret model imports encrypted Nix expressions directly into
evaluation. That keeps the files encrypted at rest in git, but it also means the
secret values are treated as regular Nix data once decrypted locally. This is
acceptable for today’s `git-crypt` flow but is the wrong pattern for a
`sops-nix` migration, because the new design should deliver secrets at runtime
rather than embedding them in evaluated config.

The current font module packages the proprietary font directory via
`builtins.path`, which would copy plaintext font files into `/nix/store` if that
module were used. That is incompatible with the requirement to keep the fonts
private.

## Proposed Architecture

### 1. Repository-wide secret policy

Add a repo-root `.sops.yaml` that defines `creation_rules` for:

- text secrets in env or YAML format
- the encrypted binary font archive

The rules will use `age` recipients only. Recipients will include:

- one user editing key for secret authoring
- one recipient per host that must decrypt secrets during activation

This keeps secret editing and host decryption explicit and local.

### 2. System integration

Add `sops-nix` as a flake input and wire its Darwin module into the shared
system assembly path so every Darwin host gets the same capabilities before any
cutover occurs.

The shared integration point should be the system composition path used by all
active Darwin hosts, rather than per-host ad hoc imports. The migration will
also configure the Darwin-supported `age` key location so each host has a stable
place to decrypt from after commit 1 lands.

### 3. Text secret delivery

Replace imported encrypted Nix files with runtime-managed secret files.

For API keys and similar shell environment values:

- store the variables in a `sops` env-format secret file
- decrypt that file at runtime via `sops-nix`
- source it from shell startup for `bash` and `fish`

This preserves the user-facing behavior: programs still see
`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and similar variables in the shell
environment. The difference is only that the values appear at shell startup from
a runtime file instead of being hard-coded into `home.sessionVariables`.

For non-secret configuration currently stored in encrypted Nix files:

- convert it back to ordinary tracked Nix where secrecy is unnecessary
- remove empty or placeholder encrypted files rather than re-encrypting them

This keeps `sops` focused on real secrets instead of functioning as a generic
container for Nix expressions.

### 4. Proprietary font handling

The proprietary fonts will move to a single encrypted archive tracked in git.

The plaintext workflow is:

1. build a tarball from the local plaintext font directory during migration
2. encrypt the tarball with `sops` in binary mode using the repo `age`
   recipients
3. track only the encrypted artifact in git
4. delete the plaintext tracked font files from the repository

The runtime workflow is:

1. `sops-nix` decrypts the archive to a private runtime or state location
2. an activation step unpacks and syncs the archive contents into a local font
   directory outside `/nix/store`
3. the activation remains idempotent so repeated rebuilds do not churn the font
   install

Because the existing proprietary font module is not currently attached to an
active host graph, the migration should preserve the ability to install those
fonts declaratively without forcing unrelated hosts to consume them.

## Rollout Plan

### Commit 1: add plumbing everywhere

This commit adds the new dependencies and host integration while leaving the
current `git-crypt`-backed repository functional.

Expected changes:

- add the `sops-nix` flake input
- wire the `sops-nix` Darwin module into shared system construction
- add `.sops.yaml`
- add any helper modules or activation scaffolding needed for later runtime
  secret sourcing
- configure the expected `age` key path for Darwin hosts
- keep all current `*.enc.nix` imports and `git-crypt` files intact

Outcome:

- every current host can build and switch to a closure that already contains the
  future decryption tooling
- no secret files have changed format yet

### Commit 2: cut over and remove git-crypt

This commit performs the actual migration.

Expected changes:

- replace `environment.enc.nix` with a `sops`-managed env secret file
- update shell startup so `bash` and `fish` source the decrypted env file
- convert `modules/ssh/default.enc.nix` into a normal tracked Nix file unless a
  concrete secret requirement emerges
- remove `home-manager/lib/shellAliases.enc.nix` if it remains empty, or convert
  it to plaintext if it gains non-secret aliases
- replace `modules/custom-fonts.enc/**` with an encrypted binary archive plus
  runtime unpack logic
- remove `.gitattributes` `git-crypt` filters
- remove `.git-crypt/`
- remove any `git-crypt` package dependency that becomes obsolete after the
  cutover

Outcome:

- the repository no longer depends on `git-crypt`
- all encrypted material lives under `sops` + `age`

## Data Flow

### Shell secrets

1. A secret env file is stored encrypted in git.
2. `sops-nix` decrypts it on the target host to a runtime path.
3. Shell init for `bash` and `fish` sources the runtime file.
4. Child processes inherit the exported variables normally.

This keeps the secret values out of the Nix store while preserving the existing
consumer contract for CLI tools and local apps.

### Font archive

1. The encrypted font archive is stored in git.
2. `sops-nix` decrypts it at activation time.
3. Activation extracts the archive into a private local font directory outside
   `/nix/store`.
4. The installed fonts become available through the standard macOS font lookup
   path.

## Error Handling and Safety

- Commit 1 must be deployable on every active Darwin host before commit 2 is
  used anywhere.
- The activation path for the font archive must fail loudly if the archive is
  missing or decryption fails, rather than silently leaving a partial install.
- Shell startup logic must tolerate the secret file being temporarily absent and
  avoid breaking interactive shells with hard failures.
- The migration should avoid keeping decrypted intermediate artifacts in tracked
  repo paths.
- The final cleanup must remove all `git-crypt` metadata only after the new
  encrypted files are present and referenced correctly.

## Verification Strategy

At minimum, verify:

- `nix flake check --all-systems`
- evaluation of both Darwin configurations after commit 1
- evaluation of both Darwin configurations after commit 2
- shell init still exports the expected API variables after switching
- the encrypted font archive can be decrypted and unpacked through the declared
  activation path
- no secret values or proprietary font payloads are copied into `/nix/store`

Because the proprietary font module is not currently attached to the active host
graph, verification should distinguish between:

- repository-level validity of the encrypted artifact and activation logic
- host-level evaluation for the active Darwin systems

## Operational Workflow After Migration

- edit or create secrets with `sops`
- distribute access by updating `.sops.yaml` recipients and rotating keys when
  necessary
- build hosts on commit 1 before deploying commit 2
- stop using `git-crypt unlock`; it is replaced by `sops` editing and
  `sops-nix` runtime decryption

## Open Questions Resolved In This Design

- API keys remain available in the shell environment.
- Proprietary fonts remain encrypted in this repository.
- The migration is intentionally split into two commits so other systems can
  absorb the decryption closure before the repo requires it.
