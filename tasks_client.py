"""Client pour créer des tâches dans Google Tasks."""

from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials

TASK_LIST_TITLE = "tâches à répartir"


def get_or_create_task_list(creds: Credentials) -> str:
    """Récupère ou crée la liste de tâches 'tâches à répartir'.

    Returns:
        L'identifiant de la liste de tâches.
    """
    service = build("tasks", "v1", credentials=creds)

    task_lists = service.tasklists().list().execute()
    for tl in task_lists.get("items", []):
        if tl["title"].lower() == TASK_LIST_TITLE.lower():
            return tl["id"]

    # La liste n'existe pas, on la crée
    new_list = service.tasklists().insert(body={"title": TASK_LIST_TITLE}).execute()
    return new_list["id"]


def get_existing_task_titles(creds: Credentials, task_list_id: str) -> set[str]:
    """Récupère les titres des tâches existantes dans une liste.

    Permet d'éviter les doublons lors de l'import.
    """
    service = build("tasks", "v1", credentials=creds)

    titles = set()
    page_token = None

    while True:
        results = (
            service.tasks()
            .list(tasklist=task_list_id, showCompleted=True,
                  showHidden=True, pageToken=page_token)
            .execute()
        )
        for task in results.get("items", []):
            if task.get("title"):
                titles.add(task["title"])

        page_token = results.get("nextPageToken")
        if not page_token:
            break

    return titles


def create_task(creds: Credentials, task_list_id: str,
                title: str, notes: str = "") -> dict:
    """Crée une tâche dans la liste spécifiée.

    Args:
        creds: Credentials OAuth2 valides.
        task_list_id: Identifiant de la liste de tâches.
        title: Titre de la tâche.
        notes: Notes/description de la tâche.

    Returns:
        La tâche créée (dict).
    """
    service = build("tasks", "v1", credentials=creds)

    body = {"title": title}
    if notes:
        body["notes"] = notes

    return service.tasks().insert(tasklist=task_list_id, body=body).execute()
