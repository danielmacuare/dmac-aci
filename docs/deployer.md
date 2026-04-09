# ACI Terraform Deployer

A Python CLI tool that orchestrates Terraform deployments for the ACI fabric. Built with [Typer](https://typer.tiangolo.com/) and [Rich](https://rich.readthedocs.io/), it wraps `terraform plan`, `apply`, and `destroy` with a live progress bar, per-resource tracking, and a timing summary table.

---

## Prerequisites

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) installed
- `terraform` binary on your `PATH` (or configured via `TF_BIN`)

---

## Setup

Navigate to the `deployer/` directory and install dependencies:

```bash
cd deployer
uv sync
```

Copy the example env file and fill in your ACI credentials:

```bash
cp .env.example .env
```

```
# .env
ACI_URL=https://sandboxapicdc.cisco.com
ACI_USERNAME=admin
ACI_PASSWORD=yourpassword
```

The deployer reads this file on startup and exits immediately with a clear error if any required field is missing.

---

## Usage

```
uv run deployer --env ENV [--module MODULE] [--dry-run | --deploy | --destroy] [--init] [--yes]
```

### Options

| Flag | Description |
|------|-------------|
| `--env prod\|dev` | Target environment. **Required.** `dev` is not yet supported. |
| `--module all\|access-pols\|tenant-pols` | Which module(s) to run. Defaults to `all`. |
| `--dry-run` | Run `terraform plan` only — no changes are applied. |
| `--deploy` | Run `terraform apply -auto-approve` directly. |
| `--destroy` | Run `terraform destroy -auto-approve` directly. Modules are destroyed in reverse deploy order. |
| `--init` | Run `terraform init` before the operation. Use on a fresh checkout or after provider changes. |
| `--yes` / `-y` | Skip confirmation prompts. Use in CI pipelines. |

`--dry-run`, `--deploy`, and `--destroy` are mutually exclusive. Exactly one must be provided. `--init` is independent and can be combined with any of them.

---

## Examples

**Preview what would be deployed (no changes):**
```bash
uv run deployer --env prod --dry-run
```

**Deploy all modules to prod:**
```bash
uv run deployer --env prod --deploy
```

**Deploy a single module:**
```bash
uv run deployer --env prod --deploy --module access-pols
```

**Destroy all resources (non-interactive, for CI):**
```bash
uv run deployer --env prod --destroy --yes
```

**First-time setup — run init before deploying:**
```bash
uv run deployer --env prod --deploy --init
```

**Run init with a dry-run to validate providers are configured correctly:**
```bash
uv run deployer --env prod --dry-run --init
```

---

## What Happens During a Run

### 1. Validation

Settings are loaded from `.env` via pydantic-settings. If `ACI_URL`, `ACI_USERNAME`, or `ACI_PASSWORD` are missing, the tool exits immediately with a descriptive error.

### 2. Confirmation prompt

For `--deploy` and `--destroy`, the tool prints the target env and modules and asks for confirmation before proceeding. Pass `--yes` to skip this.

### 3. Per-module execution

For `--deploy`, modules run in deploy order: `access-pols` → `tenant-pols`. For `--destroy`, the order is automatically reversed: `tenant-pols` → `access-pols`.

For each module:

| Step | dry-run | deploy | destroy |
|------|---------|--------|---------|
| `terraform init` | only with `--init` | only with `--init` | only with `--init` |
| `terraform plan` | yes | — | — |
| `terraform apply -auto-approve` | — | yes | — |
| `terraform destroy -auto-approve` | — | — | yes |

`terraform init` is skipped by default. Pass `--init` when running for the first time, after a provider version change, or after adding new modules.

`terraform plan` is only run explicitly with `--dry-run`. For `--deploy` and `--destroy`, terraform performs its own internal plan inline and prints the summary before acting — no separate plan step, no plan file.

ACI credentials are injected as `TF_VAR_aci_url`, `TF_VAR_aci_username`, and `TF_VAR_aci_password` environment variables — the existing `variables.tf` files are not modified.

If any module fails, the error is printed and all remaining modules are skipped.

### 4. Progress bar

For `--deploy` and `--destroy`, terraform prints its own plan summary inline before acting:

```
Plan: 5 to add, 0 to change, 2 to destroy.
```

The deployer parses this line mid-stream to set the progress bar total. As resources are created or destroyed, each `Creation complete` / `Destruction complete` line advances the bar by one, showing the resource name as it completes.

A spinner is shown until the plan summary line appears and the total is known.

```
⠸  access-pols  ████████░░░░  3/5 resources  •  00:12
```

### 5. Summary table

After all modules finish, a table is printed showing the outcome of each module:

```
┌──────────────┬───────────┬───────────┬──────────────┬──────────┐
│ Module       │ Operation │ Resources │ Duration     │ Status   │
├──────────────┼───────────┼───────────┼──────────────┼──────────┤
│ access-pols  │ deploy    │ 5         │ 00:45        │ ✓ OK     │
│ tenant-pols  │ deploy    │ 12        │ 01:23        │ ✓ OK     │
├──────────────┼───────────┼───────────┼──────────────┼──────────┤
│ Total        │           │ 17        │ 02:08        │          │
└──────────────┴───────────┴───────────┴──────────────┴──────────┘
```

If a module fails, subsequent modules show `— skipped` in the status column.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All modules completed successfully |
| `1` | One or more modules failed, or the run was aborted |

---

## Project Structure

```
deployer/
├── pyproject.toml              # uv project, entry point declaration
├── .env.example                # required variable reference
└── src/deployer/
    ├── cli.py                  # Typer app, flag validation, orchestration loop
    ├── config.py               # module registry and path resolution
    ├── runner.py               # terraform subprocess wrapper, plan parser
    ├── settings.py             # pydantic-settings .env loader
    └── ui.py                   # Rich progress bar and summary table
```

---

## Running Tests

```bash
cd deployer
uv run pytest tests/ -v
```
