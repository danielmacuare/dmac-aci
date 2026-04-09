from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    aci_url: str
    aci_username: str
    aci_password: str

    tf_bin: str = "terraform"
    repo_root: Path = Path(__file__).resolve().parent.parent.parent.parent


def load_settings() -> Settings:
    try:
        return Settings()
    except Exception as e:
        from rich.console import Console
        console = Console(stderr=True)
        console.print(f"[bold red]Configuration error:[/] {e}")
        console.print(
            "[dim]Copy [/.env.example] to [.env] and fill in the required values.[/dim]"
        )
        raise SystemExit(1)
