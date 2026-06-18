#!/usr/bin/env bash
#
# Crée l'outil MCP "Lire_Classeur_Cloture" dans l'instance n8n VVL.
#
# À LANCER SUR TON ORDINATEUR (pas dans la session Claude) — c'est lui qui peut
# joindre n8n.venividiludi.fr. Pré-requis : `curl` et `jq` installés.
#
# Utilisation :
#   export N8N_API_KEY="<ta_clef_api_n8n>"
#   bash creer_outil_cloture.sh
#
set -euo pipefail

N8N_BASE="https://n8n.venividiludi.fr/api/v1"
MCP_WF_ID="C5IMiEDCUUWsJIo2"     # VVL — Serveur MCP (Claude)
SHEETS_DOC_ID="1Zy863dDI696WIdBj9Vgtgi9IGf3kzpC2PZPWm0lB2oo"
SHEETS_CRED_ID="PnEeK4VxcOjC6zzh"
SHEETS_CRED_NAME="Google Sheets account"

: "${N8N_API_KEY:?Definir la variable avant: export N8N_API_KEY=...}"

command -v jq   >/dev/null || { echo "ERREUR: jq n'est pas installé.";   exit 1; }
command -v curl >/dev/null || { echo "ERREUR: curl n'est pas installé."; exit 1; }

AUTH=(-H "X-N8N-API-KEY: ${N8N_API_KEY}" -H "Content-Type: application/json")

# --- Chaînes contenant des apostrophes : définies via heredoc 'quoté' (sûr) ---

JSCODE=$(cat <<'EOF'
// Paramètres d'entrée (déclencheur)
const params = $('Entree').first().json || {};
const col = (params.filtre_colonne == null ? '' : params.filtre_colonne).toString().trim();
const val = (params.filtre_valeur  == null ? '' : params.filtre_valeur ).toString().trim();

// Lignes lues depuis Google Sheets
let rows = $input.all().map(i => i.json);

// Filtre optionnel par colonne / valeur (insensible à la casse)
if (col && val) {
  const v = val.toLowerCase();
  rows = rows.filter(r => ((r[col] == null ? '' : r[col]).toString().trim().toLowerCase()) === v);
}

// Total avant plafonnement, puis plafond à 250 lignes
const total = rows.length;
const LIMITE = 250;
const lignes = rows.slice(0, LIMITE);

return [{ json: {
  onglet: params.onglet || '',
  filtre_colonne: col || null,
  filtre_valeur: val || null,
  total_lignes: total,
  lignes_retournees: lignes.length,
  plafonne: total > LIMITE,
  lignes
} }];
EOF
)

AI_ONGLET=$(cat <<'EOF'
={{ $fromAI('onglet','Nom exact de l onglet du classeur de clôture 2025 à lire (ex. 07_Rapprochement_Factures, 08_Anomalies, 09_Soldes_Bancaires, 10_Statistiques, 11_Logs_Workflow).','string') }}
EOF
)

AI_COL=$(cat <<'EOF'
={{ $fromAI('filtre_colonne','Nom de la colonne sur laquelle filtrer (optionnel).','string','') }}
EOF
)

AI_VAL=$(cat <<'EOF'
={{ $fromAI('filtre_valeur','Valeur recherchée dans la colonne de filtre (optionnel).','string','') }}
EOF
)

TOOL_DESC=$(cat <<'EOF'
Lit un onglet du classeur de clôture 2025. Onglets utiles : 07_Rapprochement_Factures (rapprochements/impayés), 08_Anomalies, 09_Soldes_Bancaires (cohérence des soldes), 10_Statistiques (tableau de bord), 11_Logs_Workflow. Filtre optionnel par colonne/valeur, ex. Statut_Rapprochement = 'Non rapproché'.
EOF
)

SHEET_EXPR='={{ $json.onglet }}'

echo "==> 0) Test de la clé / accès API"
code=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH[@]}" "${N8N_BASE}/workflows?limit=1")
[ "$code" = "200" ] || { echo "ERREUR: l'API a répondu HTTP $code (clé invalide ou réseau)."; exit 1; }
echo "    OK"

# ---------------------------------------------------------------------------
# 1) Sous-workflow : Execute Workflow Trigger -> Google Sheets (read) -> Code
# ---------------------------------------------------------------------------
SUB_WF_BODY=$(jq -n \
  --arg doc "$SHEETS_DOC_ID" --arg credId "$SHEETS_CRED_ID" --arg credName "$SHEETS_CRED_NAME" \
  --arg jscode "$JSCODE" --arg sheetExpr "$SHEET_EXPR" \
  '{
    name: "VVL — MCP · Lire Classeur Clôture (sous-WF)",
    nodes: [
      { id: "trig", name: "Entree",
        type: "n8n-nodes-base.executeWorkflowTrigger", typeVersion: 1.1, position: [0,0],
        parameters: { inputSource: "workflowInputs", workflowInputs: { values: [
          { name: "onglet", type: "string" },
          { name: "filtre_colonne", type: "string" },
          { name: "filtre_valeur", type: "string" }
        ]}}},
      { id: "lire", name: "Lire onglet",
        type: "n8n-nodes-base.googleSheets", typeVersion: 4.7, position: [260,0],
        retryOnFail: true, maxTries: 3, waitBetweenTries: 2000,
        parameters: {
          operation: "read",
          documentId: { __rl: true, mode: "id", value: $doc },
          sheetName:  { __rl: true, mode: "name", value: $sheetExpr },
          options: {}
        },
        credentials: { googleSheetsOAuth2Api: { id: $credId, name: $credName } } },
      { id: "filtre", name: "Filtrer & plafonner",
        type: "n8n-nodes-base.code", typeVersion: 2, position: [520,0],
        parameters: { jsCode: $jscode } }
    ],
    connections: {
      "Entree":      { main: [[{ node: "Lire onglet",         type: "main", index: 0 }]] },
      "Lire onglet": { main: [[{ node: "Filtrer & plafonner", type: "main", index: 0 }]] }
    },
    settings: { executionOrder: "v1" }
  }')

echo "==> 1) Création du sous-workflow"
SUB_RESP=$(curl -s "${AUTH[@]}" -X POST "${N8N_BASE}/workflows" -d "$SUB_WF_BODY")
SUB_ID=$(echo "$SUB_RESP" | jq -r '.id // empty')
[ -n "$SUB_ID" ] || { echo "ERREUR à la création:"; echo "$SUB_RESP" | jq . 2>/dev/null || echo "$SUB_RESP"; exit 1; }
echo "    Sous-WF créé : $SUB_ID"
curl -s -o /dev/null "${AUTH[@]}" -X POST "${N8N_BASE}/workflows/${SUB_ID}/activate" || true

# ---------------------------------------------------------------------------
# 2) Ajout du node Tool Workflow au serveur MCP (sans toucher aux autres outils)
# ---------------------------------------------------------------------------
echo "==> 2) Lecture du serveur MCP ${MCP_WF_ID}"
CUR=$(curl -s "${AUTH[@]}" "${N8N_BASE}/workflows/${MCP_WF_ID}")
echo "$CUR" | jq -e '.nodes' >/dev/null || { echo "ERREUR: lecture serveur MCP impossible."; echo "$CUR"; exit 1; }

if echo "$CUR" | jq -e '[.nodes[].name] | index("Lire_Classeur_Cloture")' >/dev/null; then
  echo "    Le node Lire_Classeur_Cloture existe déjà — rien à ajouter."
else
  NODE=$(jq -n --arg sub "$SUB_ID" \
    --arg desc "$TOOL_DESC" --arg aiOnglet "$AI_ONGLET" --arg aiCol "$AI_COL" --arg aiVal "$AI_VAL" \
    '{
      id: "cloture_tool", name: "Lire_Classeur_Cloture",
      type: "@n8n/n8n-nodes-langchain.toolWorkflow", typeVersion: 2.2, position: [280,430],
      parameters: {
        description: $desc,
        workflowId: { __rl: true, value: $sub, mode: "list", cachedResultName: "VVL — MCP · Lire Classeur Clôture (sous-WF)" },
        workflowInputs: {
          mappingMode: "defineBelow",
          value: { "onglet": $aiOnglet, "filtre_colonne": $aiCol, "filtre_valeur": $aiVal },
          matchingColumns: [],
          schema: [
            { id: "onglet",         displayName: "onglet",         required: true,  defaultMatch: false, display: true, type: "string", canBeUsedToMatch: false, removed: false },
            { id: "filtre_colonne", displayName: "filtre_colonne", required: false, defaultMatch: false, display: true, type: "string", canBeUsedToMatch: false, removed: false },
            { id: "filtre_valeur",  displayName: "filtre_valeur",  required: false, defaultMatch: false, display: true, type: "string", canBeUsedToMatch: false, removed: false }
          ],
          attemptToConvertTypes: false, convertFieldsToString: true
        }
      }
    }')

  PUT_BODY=$(echo "$CUR" | jq --argjson node "$NODE" '
    { name, nodes, connections, settings }
    | .nodes += [$node]
    | .connections["Lire_Classeur_Cloture"] = { ai_tool: [[{ node: "MCP Server Trigger", type: "ai_tool", index: 0 }]] }
  ')

  echo "==> 3) Mise à jour du serveur MCP (PUT)"
  curl -s -o /dev/null "${AUTH[@]}" -X POST "${N8N_BASE}/workflows/${MCP_WF_ID}/deactivate" || true
  UPD=$(curl -s "${AUTH[@]}" -X PUT "${N8N_BASE}/workflows/${MCP_WF_ID}" -d "$PUT_BODY")
  echo "$UPD" | jq -e '.id' >/dev/null || { echo "ERREUR à la mise à jour:"; echo "$UPD" | jq . 2>/dev/null || echo "$UPD"; exit 1; }
  echo "    Node ajouté."
fi

echo "==> 4) Activation du serveur MCP"
curl -s -o /dev/null "${AUTH[@]}" -X POST "${N8N_BASE}/workflows/${MCP_WF_ID}/activate" || true

echo
echo "✅ Terminé."
echo "   Sous-workflow : ${SUB_ID:-déjà présent}"
echo "   Serveur MCP   : ${MCP_WF_ID} (outil Lire_Classeur_Cloture actif)"
echo "   ⚠️  Pense à régénérer ta clé API n8n maintenant."
