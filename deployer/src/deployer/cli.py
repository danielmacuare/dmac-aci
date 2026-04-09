from __future__ import annotations

import typer

from deployer import ui
from deployer.config import get_modules
from deployer.runner import ModuleResult, run_module
from deployer.settings import load_settings

app = typer.Typer(
    name="deployer",
    help="ACI Terraform Deployer",
    add_completion=False,
)


def _exclusive(*flags: bool) -> bool:
    return sum(bool(f) for f in flags) > 1


@app.command()
def main(
    env: str = typer.Option(..., help="Target environment: prod | dev"),
    module: str = typer.Option(
        "all", help="Module to run: all | access-pols | tenant-pols"
    ),
    dry_run: bool = typer.Option(False, "--dry-run", help="Plan only, no apply"),
    deploy: bool = typer.Option(False, "--deploy", help="Init → plan → apply"),
    destroy: bool = typer.Option(False, "--destroy", help="Plan → destroy"),
    init: bool = typer.Option(
        False, "--init", help="Run terraform init before the operation"
    ),
    yes: bool = typer.Option(
        False, "--yes", "-y", help="Skip confirmation prompts (CI mode)"
    ),
) -> None:
    # ── validate flags ────────────────────────────────────────────────────────
    if _exclusive(dry_run, deploy, destroy):
        typer.echo(
            "Error: --dry-run, --deploy, and --destroy are mutually exclusive.",
            err=True,
        )
        raise typer.Exit(1)

    if not any([dry_run, deploy, destroy]):
        typer.echo(
            "Error: one of --dry-run, --deploy, or --destroy is required.", err=True
        )
        raise typer.Exit(1)

    operation = "dry-run" if dry_run else ("deploy" if deploy else "destroy")

    # ── load settings ─────────────────────────────────────────────────────────
    settings = load_settings()

    # ── resolve modules ───────────────────────────────────────────────────────
    try:
        modules = get_modules(env, module, settings.repo_root, operation)
    except ValueError as e:
        typer.echo(f"Error: {e}", err=True)
        raise typer.Exit(1)

    # ── confirm ───────────────────────────────────────────────────────────────
    if operation in ("deploy", "destroy") and not yes:
        names = ", ".join(n for n, _ in modules)
        typer.echo(f"\n  env:       {env}")
        typer.echo(f"  modules:   {names}")
        typer.echo(f"  operation: {operation}\n")
        if not ui.confirm(f"Proceed with {operation}?"):
            typer.echo("Aborted.")
            raise typer.Exit(0)

    # ── run ───────────────────────────────────────────────────────────────────
    results: list[ModuleResult] = []
    failed = False

    for name, path in modules:
        if failed:
            skipped = ModuleResult(name=name, operation=operation, skipped=True)
            results.append(skipped)
            continue

        ui.console.rule(f"[bold]{name}[/]")

        with ui.ModuleProgress(name, operation) as prog:

            def _step_cb(stage, cmd, _p=prog):
                _p.set_step(stage, cmd)

            def _plan_cb(summary, _p=prog):
                _p.set_plan(summary)

            def _progress_cb(resource, _p=prog):
                _p.advance(resource)

            result = run_module(
                name=name,
                module_path=path,
                operation=operation,
                settings=settings,
                run_init=init,
                step_callback=_step_cb,
                plan_callback=_plan_cb,
                progress_callback=_progress_cb,
            )
            prog.finish(result.status)

        results.append(result)

        if result.status == "failed":
            ui.print_error(name, result.error_output)
            failed = True

    # ── summary ───────────────────────────────────────────────────────────────
    ui.print_summary_table(results)

    if failed:
        raise typer.Exit(1)
