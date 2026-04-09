from __future__ import annotations

from typing import TYPE_CHECKING

from rich.console import Console
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TaskProgressColumn,
    TextColumn,
    TimeElapsedColumn,
)
from rich.table import Table

if TYPE_CHECKING:
    from deployer.runner import ModuleResult, PlanSummary

console = Console()


def _fmt_duration(seconds: float) -> str:
    m = int(seconds) // 60
    s = int(seconds) % 60
    return f"{m:02d}:{s:02d}"


class ModuleProgress:
    """Context manager that wraps a single module's rich Progress bar."""

    def __init__(self, name: str, operation: str) -> None:
        self.name = name
        self.operation = operation
        self._progress = Progress(
            SpinnerColumn(),
            TextColumn("[bold cyan]{task.description}"),
            BarColumn(bar_width=30),
            TaskProgressColumn(),
            TimeElapsedColumn(),
            console=console,
            transient=False,
        )
        self._task_id = None
        self._total = 0

    def __enter__(self) -> "ModuleProgress":
        self._progress.__enter__()
        self._task_id = self._progress.add_task(
            f"{self.name}  [dim]planning…[/dim]",
            total=None,
        )
        return self

    def __exit__(self, *args) -> None:
        self._progress.__exit__(*args)

    def set_step(self, stage: str, display_cmd: str) -> None:
        self._progress.update(
            self._task_id,
            description=f"{self.name}  [bold]{stage}:[/bold] [dim]{display_cmd}[/dim]",
        )

    def set_plan(self, summary: "PlanSummary") -> None:
        if self.operation == "deploy":
            self._total = summary.to_add + summary.to_change
        elif self.operation == "destroy":
            self._total = summary.to_destroy
        else:
            self._total = summary.to_add + summary.to_change + summary.to_destroy

        parts = []
        if summary.to_add:
            parts.append(f"[green]{summary.to_add} resources to add[/]")
        if summary.to_change:
            parts.append(f"[yellow]{summary.to_change} resources to change[/]")
        if summary.to_destroy:
            parts.append(f"[red]{summary.to_destroy} resources to destroy[/]")

        plan_str = ", ".join(parts) if parts else "[dim]no changes[/dim]"
        console.print(f"  [dim]→ {self.name}:[/dim] {plan_str}")

        self._progress.update(
            self._task_id,
            description=f"{self.name}  [dim]{self.operation}…[/dim]",
            total=max(self._total, 1),
            completed=0,
        )

    def advance(self, resource: str) -> None:
        label = resource[:40] + "…" if len(resource) > 40 else resource
        self._progress.update(
            self._task_id,
            description=f"{self.name}  [dim]{label}[/dim]",
            advance=1,
        )

    def finish(self, status: str) -> None:
        icon = "[green]✓[/]" if status == "ok" else "[red]✗[/]"
        self._progress.update(
            self._task_id,
            description=f"{self.name}  {icon}",
            completed=max(self._total, 1),
        )


def print_summary_table(results: list["ModuleResult"]) -> None:
    table = Table(title="Deployment Summary", show_lines=True)
    table.add_column("Module", style="bold")
    table.add_column("Operation")
    table.add_column("Resources", justify="right")
    table.add_column("Duration", justify="right")
    table.add_column("Status")

    total_resources = 0
    total_seconds = 0.0

    for r in results:
        if r.skipped:
            table.add_row(r.name, r.operation, "—", "—", "[dim]— skipped[/dim]")
            continue

        if r.operation == "deploy":
            res_count = r.plan_summary.to_add + r.plan_summary.to_change
        elif r.operation == "destroy":
            res_count = r.plan_summary.to_destroy
        else:
            res_count = (
                r.plan_summary.to_add
                + r.plan_summary.to_change
                + r.plan_summary.to_destroy
            )

        total_resources += res_count
        total_seconds += r.duration_seconds

        status_str = "[green]✓ OK[/]" if r.status == "ok" else "[red]✗ FAILED[/]"
        table.add_row(
            r.name,
            r.operation,
            str(res_count),
            _fmt_duration(r.duration_seconds),
            status_str,
        )

    table.add_section()
    table.add_row(
        "[bold]Total[/]",
        "",
        str(total_resources),
        _fmt_duration(total_seconds),
        "",
    )

    console.print()
    console.print(table)


def print_error(module: str, error_output: str) -> None:
    from rich.panel import Panel

    console.print(
        Panel(
            error_output,
            title=f"[red]Error in {module}[/]",
            border_style="red",
        )
    )


def confirm(prompt: str) -> bool:
    return console.input(f"{prompt} [bold][y/N][/bold]: ").strip().lower() == "y"
