#!/usr/bin/env python3
"""Gmail vers Google Tasks — Transfert des emails de la boîte de réception
vers la liste de tâches "tâches à répartir"."""

import argparse
import sys

from auth import get_credentials
from gmail_client import get_inbox_emails
from tasks_client import create_task, get_existing_task_titles, get_or_create_task_list


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Transfère les emails Gmail (boîte de réception) "
                    "vers Google Tasks dans la liste 'tâches à répartir'."
    )
    parser.add_argument(
        "--max-emails", type=int, default=50,
        help="Nombre maximum d'emails à traiter (défaut : 50)."
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Affiche les tâches qui seraient créées sans les créer."
    )
    args = parser.parse_args()

    # 1. Authentification
    print("Authentification auprès de Google...")
    creds = get_credentials()

    # 2. Récupération des emails
    print(f"Récupération des emails de la boîte de réception (max {args.max_emails})...")
    emails = get_inbox_emails(creds, max_results=args.max_emails)

    if not emails:
        print("Aucun email trouvé dans la boîte de réception.")
        return

    print(f"{len(emails)} email(s) trouvé(s).")

    # 3. Préparation de la liste Google Tasks
    print("Récupération/création de la liste 'tâches à répartir'...")
    task_list_id = get_or_create_task_list(creds)

    # 4. Récupération des tâches existantes pour éviter les doublons
    existing_titles = get_existing_task_titles(creds, task_list_id)

    # 5. Création des tâches
    created = 0
    skipped = 0

    for email in emails:
        task_title = f"[Mail] {email.subject}"

        if task_title in existing_titles:
            skipped += 1
            continue

        notes = f"De : {email.sender}\nDate : {email.date}\n\n{email.snippet}"

        if args.dry_run:
            print(f"  [DRY-RUN] Tâche : {task_title}")
        else:
            create_task(creds, task_list_id, title=task_title, notes=notes)

        created += 1

    # 6. Résumé
    print(f"\nRésumé :")
    print(f"  - Tâches créées : {created}")
    print(f"  - Doublons ignorés : {skipped}")

    if args.dry_run:
        print("  (mode dry-run — aucune tâche n'a réellement été créée)")


if __name__ == "__main__":
    main()
