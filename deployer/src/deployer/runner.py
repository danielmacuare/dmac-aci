import os
import re
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

from deployer.settings import Settings


@dataclass
class PlanSummary:
    to_add: int = 0
    to_change: int = 0
    to_destroy: int = 0

    @property
    def total_for_deploy(self) -> int:
        return self.to_add + self.to_change

    @property
    def total_for_destroy(self) -> int:
        return self.to_destroy


@dataclass
class ModuleResult:
    name: str
    operation: str
    duration_seconds: float = 0.0
    plan_summary: PlanSummary = field(default_factory=PlanSummary)
    status: str = "ok"
    error_output: str = ""
    skipped: bool = False


_PLAN_RE = re.compile(
    r"Plan:\s+(\d+) to add,\s+(\d+) to change,\s+(\d+) to destroy"
)
_COMPLETE_RE = re.compile(
    r"^\s*([\w.\"/-]+):\s+(Creation|Destruction) complete after"
)
_NO_CHANGES_RE = re.compile(r"No changes\.|Your infrastructure matches the configuration")


def _build_env(settings: Settings) -> dict[str, str]:
    env = os.environ.copy()
    env["TF_VAR_aci_url"] = settings.aci_url
    env["TF_VAR_aci_username"] = settings.aci_username
    env["TF_VAR_aci_password"] = settings.aci_password
    env["TF_IN_AUTOMATION"] = "1"
    return env


def _run_streaming(
    cmd: list[str],
    cwd: Path,
    env: dict[str, str],
    line_callback: Callable[[str], None] | None = None,
) -> tuple[int, list[str]]:
    lines: list[str] = []
    proc = subprocess.Popen(
        cmd,
        cwd=str(cwd),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    assert proc.stdout is not None
    for line in proc.stdout:
        line = line.rstrip("\n")
        lines.append(line)
        if line_callback:
            line_callback(line)
    proc.wait()
    return proc.returncode, lines


def parse_plan_summary(lines: list[str]) -> PlanSummary:
    for line in reversed(lines):
        m = _PLAN_RE.search(line)
        if m:
            return PlanSummary(
                to_add=int(m.group(1)),
                to_change=int(m.group(2)),
                to_destroy=int(m.group(3)),
            )
        if _NO_CHANGES_RE.search(line):
            return PlanSummary()
    return PlanSummary()


def run_module(
    name: str,
    module_path: Path,
    operation: str,
    settings: Settings,
    run_init: bool = False,
    step_callback: Callable[[str, str], None] | None = None,
    plan_callback: Callable[[PlanSummary], None] | None = None,
    progress_callback: Callable[[str], None] | None = None,
    raw_line_callback: Callable[[str], None] | None = None,
) -> ModuleResult:
    """
    step_callback(stage, display_cmd) — called before each terraform command.
      stage:       human label, e.g. "Initializing", "Planning", "Deploying"
      display_cmd: the command as it would appear on a terminal, flags stripped
                   to only the meaningful ones.
    """
    result = ModuleResult(name=name, operation=operation)
    env = _build_env(settings)
    start = time.monotonic()
    plan_summary_fired = False

    tf = settings.tf_bin

    def _line(line: str) -> None:
        if raw_line_callback:
            raw_line_callback(line)

    def _step(stage: str, display_cmd: str) -> None:
        if step_callback:
            step_callback(stage, display_cmd)

    # ── init (optional) ───────────────────────────────────────────────────────
    if run_init:
        _step("Initializing", f"{tf} init")
        rc, lines = _run_streaming(
            [tf, "init", "-input=false", "-no-color"],
            module_path,
            env,
            _line,
        )
        if rc != 0:
            result.status = "failed"
            result.error_output = "\n".join(lines[-30:])
            result.duration_seconds = time.monotonic() - start
            return result

    # ── dry-run: plan only ────────────────────────────────────────────────────
    if operation == "dry-run":
        _step("Planning", f"{tf} plan")
        rc, lines = _run_streaming(
            [tf, "plan", "-input=false", "-no-color"],
            module_path,
            env,
            _line,
        )
        if rc != 0:
            result.status = "failed"
            result.error_output = "\n".join(lines[-30:])
        else:
            summary = parse_plan_summary(lines)
            result.plan_summary = summary
            if plan_callback:
                plan_callback(summary)
        result.duration_seconds = time.monotonic() - start
        return result

    # ── deploy: terraform apply -auto-approve ─────────────────────────────────
    # ── destroy: terraform destroy -auto-approve ──────────────────────────────
    # terraform prints its own plan summary inline before acting, which we parse
    # mid-stream to set the progress bar total.
    if operation == "deploy":
        action_cmd = [tf, "apply", "-auto-approve", "-input=false", "-no-color"]
        _step("Deploying", f"{tf} apply -auto-approve")
    else:
        action_cmd = [tf, "destroy", "-auto-approve", "-input=false", "-no-color"]
        _step("Destroying", f"{tf} destroy -auto-approve")

    def _action_line(line: str) -> None:
        nonlocal plan_summary_fired
        _line(line)
        if not plan_summary_fired:
            m = _PLAN_RE.search(line)
            if m:
                summary = PlanSummary(
                    to_add=int(m.group(1)),
                    to_change=int(m.group(2)),
                    to_destroy=int(m.group(3)),
                )
                result.plan_summary = summary
                if plan_callback:
                    plan_callback(summary)
                plan_summary_fired = True
            elif _NO_CHANGES_RE.search(line):
                summary = PlanSummary()
                result.plan_summary = summary
                if plan_callback:
                    plan_callback(summary)
                plan_summary_fired = True
        m = _COMPLETE_RE.match(line)
        if m and progress_callback:
            progress_callback(m.group(1))

    rc, lines = _run_streaming(action_cmd, module_path, env, _action_line)
    if rc != 0:
        result.status = "failed"
        result.error_output = "\n".join(lines[-30:])

    result.duration_seconds = time.monotonic() - start
    return result
