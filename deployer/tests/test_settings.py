import pytest
from pydantic import ValidationError


def test_missing_required_fields(monkeypatch, tmp_path):
    """Settings raises ValidationError when required ACI fields are absent."""
    monkeypatch.chdir(tmp_path)  # no .env in this dir

    # Unset any env vars that might be set in the real environment
    for key in ("ACI_URL", "ACI_USERNAME", "ACI_PASSWORD"):
        monkeypatch.delenv(key, raising=False)

    with pytest.raises((ValidationError, SystemExit)):
        from deployer.settings import Settings
        Settings()


def test_all_required_fields_present(monkeypatch, tmp_path):
    """Settings loads successfully when all required fields are provided."""
    monkeypatch.setenv("ACI_URL", "https://example.com")
    monkeypatch.setenv("ACI_USERNAME", "admin")
    monkeypatch.setenv("ACI_PASSWORD", "secret")

    from deployer.settings import Settings
    s = Settings()
    assert s.aci_url == "https://example.com"
    assert s.aci_username == "admin"
    assert s.aci_password == "secret"
    assert s.tf_bin == "terraform"


def test_optional_tf_bin_override(monkeypatch):
    """TF_BIN can be overridden via env."""
    monkeypatch.setenv("ACI_URL", "https://example.com")
    monkeypatch.setenv("ACI_USERNAME", "admin")
    monkeypatch.setenv("ACI_PASSWORD", "secret")
    monkeypatch.setenv("TF_BIN", "/usr/local/bin/terraform")

    from deployer.settings import Settings
    s = Settings()
    assert s.tf_bin == "/usr/local/bin/terraform"
