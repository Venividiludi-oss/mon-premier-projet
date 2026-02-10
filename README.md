# mon-premier-projet

## Workflow n8n : Email vers Google Tasks

Ce workflow n8n transfère automatiquement chaque nouvel e-mail reçu dans votre boîte de réception vers Google Tasks, dans la liste **"tâches à répartir"**.

### Fonctionnement

1. **Déclencheur IMAP** : surveille votre boîte de réception en continu
2. **Création de tâche** : pour chaque nouvel e-mail, une tâche est créée dans Google Tasks avec :
   - **Titre** : l'objet de l'e-mail
   - **Notes** : l'expéditeur, la date et le contenu texte du message

### Installation sur n8n (Hostinger)

#### Étape 1 — Importer le workflow

1. Ouvrez votre instance n8n sur Hostinger
2. Allez dans **Workflows** > **Add workflow** (ou bouton `+`)
3. Cliquez sur les `...` (menu) en haut à droite puis **Import from file**
4. Sélectionnez le fichier `workflows/email-to-google-tasks.json`

#### Étape 2 — Configurer les credentials IMAP (votre boîte mail)

1. Cliquez sur le noeud **"Nouvel Email (IMAP)"**
2. Dans **Credential to connect with**, cliquez sur **Create New Credential**
3. Remplissez les champs :
   - **User** : votre adresse e-mail complète
   - **Password** : votre mot de passe (ou mot de passe d'application)
   - **Host** : le serveur IMAP de votre fournisseur (ex : `imap.gmail.com`, `imap.hostinger.com`, `outlook.office365.com`)
   - **Port** : `993` (IMAP SSL par défaut)
   - **SSL/TLS** : activé
4. Cliquez sur **Save**

> **Gmail** : vous devez utiliser un mot de passe d'application (pas votre mot de passe Google). Allez dans [Mots de passe d'application Google](https://myaccount.google.com/apppasswords) pour en générer un.

#### Étape 3 — Configurer les credentials Google Tasks

1. Cliquez sur le noeud **"Créer Tâche Google"**
2. Dans **Credential to connect with**, cliquez sur **Create New Credential**
3. Sélectionnez **Google Tasks OAuth2 API**
4. Suivez le processus d'authentification OAuth2 :
   - Vous aurez besoin d'un **Client ID** et **Client Secret** depuis la [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Activez l'API **Google Tasks API** dans votre projet Google Cloud
   - Ajoutez l'URL de callback n8n dans les URIs de redirection autorisés
5. Cliquez sur **Connect my account** et autorisez l'accès

#### Étape 4 — Sélectionner la liste "tâches à répartir"

1. Cliquez sur le noeud **"Créer Tâche Google"**
2. Dans le champ **Task List**, sélectionnez **"tâches à répartir"** dans le menu déroulant
   - Si cette liste n'existe pas encore, créez-la d'abord dans [Google Tasks](https://tasks.google.com/) ou dans la barre latérale de Gmail
3. Sauvegardez le noeud

#### Étape 5 — Activer le workflow

1. Cliquez sur le toggle **Active** en haut à droite pour passer le workflow en mode actif
2. Le workflow va maintenant surveiller votre boîte mail en continu et créer une tâche pour chaque nouvel e-mail

### Structure du projet

```
workflows/
  email-to-google-tasks.json   # Le workflow n8n à importer
README.md                       # Ce fichier
```
