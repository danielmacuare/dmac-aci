from collections import OrderedDict
from pathlib import Path


MODULES: dict[str, OrderedDict[str, str]] = {
    "prod": OrderedDict([
        ("access-pols", "tform/tenants/prod/access-pols"),
        ("tenant-pols", "tform/tenants/prod/tenant-pols"),
    ]),
}

DEPLOY_ORDER = ["access-pols", "tenant-pols"]


def get_modules(env: str, module: str, repo_root: Path, operation: str = "deploy") -> list[tuple[str, Path]]:
    if env == "dev":
        raise ValueError("dev environment is not yet supported")

    if env not in MODULES:
        raise ValueError(f"Unknown environment: {env!r}")

    env_modules = MODULES[env]

    if module == "all":
        names = list(reversed(DEPLOY_ORDER)) if operation == "destroy" else DEPLOY_ORDER
    else:
        if module not in env_modules:
            raise ValueError(
                f"Unknown module {module!r} for env {env!r}. "
                f"Available: {list(env_modules)}"
            )
        names = [module]

    return [(name, repo_root / env_modules[name]) for name in names]
