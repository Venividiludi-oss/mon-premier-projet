"""Client pour récupérer les emails de la boîte de réception Gmail."""

from dataclasses import dataclass
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials


@dataclass
class Email:
    """Représente un email simplifié."""
    id: str
    subject: str
    sender: str
    snippet: str
    date: str


def _get_header(headers: list[dict], name: str) -> str:
    """Extrait la valeur d'un header d'email par son nom."""
    for header in headers:
        if header["name"].lower() == name.lower():
            return header["value"]
    return ""


def get_inbox_emails(creds: Credentials, max_results: int = 50) -> list[Email]:
    """Récupère les emails de la boîte de réception.

    Args:
        creds: Credentials OAuth2 valides.
        max_results: Nombre maximum d'emails à récupérer.

    Returns:
        Liste d'objets Email.
    """
    service = build("gmail", "v1", credentials=creds)

    results = (
        service.users()
        .messages()
        .list(userId="me", labelIds=["INBOX"], maxResults=max_results)
        .execute()
    )

    messages = results.get("messages", [])
    if not messages:
        return []

    emails = []
    for msg_ref in messages:
        msg = (
            service.users()
            .messages()
            .get(userId="me", id=msg_ref["id"], format="metadata",
                 metadataHeaders=["Subject", "From", "Date"])
            .execute()
        )

        headers = msg.get("payload", {}).get("headers", [])
        emails.append(
            Email(
                id=msg["id"],
                subject=_get_header(headers, "Subject") or "(sans objet)",
                sender=_get_header(headers, "From"),
                snippet=msg.get("snippet", ""),
                date=_get_header(headers, "Date"),
            )
        )

    return emails
