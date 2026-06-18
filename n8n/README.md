# Outil MCP « Lire_Classeur_Cloture » — définitions n8n

Ces fichiers contiennent les définitions prêtes à importer pour ajouter, au serveur
MCP VVL, un outil de lecture du classeur de clôture 2025.

> **Pourquoi des fichiers et pas une création directe dans n8n ?**
> Le seul outil n8n exposé via MCP dans cette session (`Piloter_n8n`) est en
> lecture seule (`GET` + `activate`/`deactivate`). L'API REST n8n répond `403`
> sans clé API, et aucune clé n'est disponible dans cet environnement. Impossible
> donc de créer/modifier un workflow directement. Ces JSON permettent de le faire
> manuellement (ou via un outil MCP autorisé en écriture).

## Contenu

| Fichier | Rôle |
|---|---|
| `VVL_MCP_Lire_Classeur_Cloture_sous-WF.json` | Sous-workflow complet (Execute Workflow Trigger → Google Sheets read → Code). Importable tel quel. |
| `MCP_node_Lire_Classeur_Cloture.json` | Node `Tool Workflow` à ajouter au serveur MCP `C5IMiEDCUUWsJIo2`, + la connexion `ai_tool` correspondante. |

## Paramètres clés (déjà renseignés)

- **Document Google Sheets** : `1Zy863dDI696WIdBj9Vgtgi9IGf3kzpC2PZPWm0lB2oo`
- **Credential Google Sheets** : `PnEeK4VxcOjC6zzh` — « Google Sheets account »
  (celui utilisé par les workflows « Clôture 2025 », vérifié présent).
- **Onglet** : dynamique `={{ $json.onglet }}`.
- **Filtre** : `filtre_colonne` / `filtre_valeur` optionnels (égalité, insensible à la casse).
- **Plafond** : 250 lignes. Sortie : `total_lignes` (avant plafond), `lignes_retournees`,
  `plafonne`, `lignes`.

## Procédure d'application

1. **Importer le sous-workflow** : dans n8n → *Import from File* →
   `VVL_MCP_Lire_Classeur_Cloture_sous-WF.json`. Vérifier que le node Google Sheets
   pointe bien sur le credential « Google Sheets account ». **Sauvegarder**.
2. Noter l'**id** du sous-workflow créé (dans l'URL).
3. **Ajouter le node** au serveur MCP `VVL — Serveur MCP (Claude)` (`C5IMiEDCUUWsJIo2`) :
   coller le node de `MCP_node_Lire_Classeur_Cloture.json`, remplacer
   `<ID_DU_SOUS_WF>` par l'id de l'étape 2, et relier sa sortie `ai_tool` au
   `MCP Server Trigger`. **Ne pas toucher** aux 4 outils existants
   (Google_Tasks_Lister, Google_Tasks_Creer, Drive_Recherche, Piloter_n8n).
4. **Sauvegarder** puis **activer** le workflow serveur MCP.
