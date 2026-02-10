# Gmail vers Google Tasks

Transfère automatiquement les emails de votre boîte de réception Gmail vers une liste Google Tasks nommée **"tâches à répartir"**.

## Fonctionnalités

- Récupère les emails de la boîte de réception Gmail
- Crée une tâche par email dans la liste "tâches à répartir" (créée automatiquement si absente)
- Détection des doublons : un email déjà importé ne sera pas recréé
- Chaque tâche contient l'expéditeur, la date et un aperçu du contenu
- Mode `--dry-run` pour simuler sans rien créer

## Prérequis

1. **Python 3.10+**
2. **Un projet Google Cloud** avec les API suivantes activées :
   - Gmail API
   - Google Tasks API
3. **Un fichier `credentials.json`** (identifiants OAuth 2.0) téléchargé depuis la [Google Cloud Console](https://console.cloud.google.com/apis/credentials)

## Installation

```bash
pip install -r requirements.txt
```

## Configuration Google Cloud

1. Rendez-vous sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un projet (ou sélectionnez un projet existant)
3. Activez les API **Gmail API** et **Tasks API** :
   - Menu > APIs & Services > Library > cherchez "Gmail API" > Enable
   - Menu > APIs & Services > Library > cherchez "Tasks API" > Enable
4. Créez des identifiants OAuth 2.0 :
   - Menu > APIs & Services > Credentials > Create Credentials > OAuth client ID
   - Type : "Desktop app"
   - Téléchargez le fichier JSON et renommez-le `credentials.json`
5. Placez `credentials.json` à la racine du projet

## Utilisation

```bash
# Lancement standard (transfère jusqu'à 50 emails)
python main.py

# Limiter le nombre d'emails traités
python main.py --max-emails 20

# Simuler sans créer de tâches
python main.py --dry-run
```

Au premier lancement, votre navigateur s'ouvrira pour vous demander d'autoriser l'accès à Gmail et Google Tasks. Les tokens seront sauvegardés dans `token.json` pour les exécutions suivantes.

## Structure du projet

```
├── main.py            # Point d'entrée — orchestre le flux complet
├── auth.py            # Authentification OAuth2 Google
├── gmail_client.py    # Récupération des emails Gmail
├── tasks_client.py    # Gestion des tâches Google Tasks
├── requirements.txt   # Dépendances Python
└── .gitignore         # Fichiers exclus du dépôt
```
