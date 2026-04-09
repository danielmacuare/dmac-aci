import pytest
from pathlib import Path

from deployer.config import get_modules, DEPLOY_ORDER


FAKE_ROOT = Path("/fake/repo")


def test_get_modules_all_prod():
    modules = get_modules("prod", "all", FAKE_ROOT)
    names = [n for n, _ in modules]
    assert names == DEPLOY_ORDER


def test_get_modules_single():
    modules = get_modules("prod", "access-pols", FAKE_ROOT)
    assert len(modules) == 1
    assert modules[0][0] == "access-pols"


def test_get_modules_paths_are_absolute():
    modules = get_modules("prod", "all", FAKE_ROOT)
    for _, path in modules:
        assert path.is_absolute()
        assert str(path).startswith(str(FAKE_ROOT))


def test_get_modules_deploy_order():
    modules = get_modules("prod", "all", FAKE_ROOT, operation="deploy")
    names = [n for n, _ in modules]
    assert names.index("access-pols") < names.index("tenant-pols")


def test_get_modules_destroy_order_is_reversed():
    modules = get_modules("prod", "all", FAKE_ROOT, operation="destroy")
    names = [n for n, _ in modules]
    assert names.index("tenant-pols") < names.index("access-pols")


def test_dev_env_raises():
    with pytest.raises(ValueError, match="not yet supported"):
        get_modules("dev", "all", FAKE_ROOT)


def test_unknown_module_raises():
    with pytest.raises(ValueError, match="Unknown module"):
        get_modules("prod", "nonexistent", FAKE_ROOT)


def test_unknown_env_raises():
    with pytest.raises(ValueError, match="Unknown environment"):
        get_modules("staging", "all", FAKE_ROOT)
