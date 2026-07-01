# Infrastructure as Code with Bicep + Azure Pipelines (POC)

Provision an **Azure App Service (Linux)** and a **Storage Account** using **Bicep**
(with reusable modules) and deploy/destroy them via an **Azure Pipeline** using the
Azure CLI task.

```
 Azure DevOps Pipeline
        │  (AzureCLI@2 task)
        ▼
 az deployment group create --template-file main.bicep
        │
        ▼
 Resource Group ──► App Service (Linux)  +  Storage Account
```

---

## Repo structure

```
bicep-azurepipelines-poc/
├── bicep/
│   ├── main.bicep                 # orchestrator — composes the modules
│   ├── main.dev.bicepparam        # parameter values for dev
│   └── modules/
│       ├── storage.bicep          # reusable Storage Account module
│       └── appservice.bicep       # reusable App Service (plan + web app) module
├── pipelines/
│   └── azure-pipelines.yml        # validate → deploy → destroy (parameterized)
└── README.md
```

**Why modules?** (addresses the hint) The storage and app-service definitions live in
`modules/` and are reused by `main.bicep`. You can drop the same module into other
templates/environments without copy-pasting resource code.

---

## Prerequisites

- Azure subscription + Azure DevOps organization.
- **Azure CLI** with the **Bicep** extension (`az bicep install`) — for local validation.
- An **ARM service connection** in Azure DevOps (used by the pipeline).

---

## Step 1 — Write the Bicep files
Already done in this repo:
- `modules/storage.bicep` — StorageV2 account, TLS 1.2, HTTPS-only, no public blob access.
- `modules/appservice.bicep` — Linux App Service Plan (B1) + Web App (Node 18, HTTPS-only).
- `main.bicep` — wires both modules, generates globally-unique names via `uniqueString()`,
  and emits outputs (storage name, web app name, web app URL).

## Step 2 — Validate Bicep locally
```bash
# Compile to ARM (catches syntax/type errors + linter warnings):
az bicep build --file bicep/main.bicep

# Validate parameter file:
az bicep build-params --file bicep/main.dev.bicepparam

# Preview exactly what will change (requires a resource group + login):
az login
az group create -n rg-bicep-poc -l eastus
az deployment group what-if \
  -g rg-bicep-poc \
  --template-file bicep/main.bicep \
  --parameters bicep/main.dev.bicepparam
```

## Step 3 — Create the Azure Pipeline
1. Push this repo to Azure Repos (or GitHub).
2. Azure DevOps → **Project Settings → Service connections** → create an
   **Azure Resource Manager** connection named **`azure-arm-connection`**
   (matches `azureServiceConnection` in the YAML).
3. Azure DevOps → **Pipelines → New pipeline → existing YAML** →
   select `pipelines/azure-pipelines.yml`.
4. (Optional) Create an **Environment** named `bicep-poc` and add an approval check.

## Step 4 — Deploy & monitor
- Click **Run pipeline** → choose **action = `deploy`**.
- Pipeline stages:
  1. **Validate** — `az bicep build` + `what-if` preview.
  2. **Deploy** — `az deployment group create` provisions the resources.
- In the **Azure Portal** open the resource group **`rg-bicep-poc`** → verify the
  App Service and Storage Account. The deploy step also prints the outputs
  (web app URL, storage name) in the pipeline logs.

## Step 5 — Destroy (same pipeline)
- Click **Run pipeline** → choose **action = `destroy`**.
- The **Destroy** stage runs `az group delete` to remove all resources.

---

## Local commands quick reference
```bash
az bicep build --file bicep/main.bicep          # lint/compile
az bicep version                                # check bicep CLI
az deployment group create -g rg-bicep-poc \    # manual deploy (no pipeline)
  --template-file bicep/main.bicep \
  --parameters bicep/main.dev.bicepparam
az group delete -n rg-bicep-poc --yes           # manual teardown
```

---

## Expected outcome
- ✅ App Service + Storage Account deployed via the pipeline.
- ✅ Resources visible in the Azure Portal under `rg-bicep-poc`.
- ✅ Same pipeline tears everything down with `action = destroy`.

## Interview / demo talking points
- **Bicep vs ARM:** Bicep is a cleaner DSL that transpiles to ARM JSON — less verbose,
  modules, type safety, and no manual `dependsOn` in most cases.
- **Modules** = reusable, parameterized building blocks (the hint).
- **`what-if`** = safe preview of changes before applying (like `terraform plan`).
- **Idempotent:** re-running converges to the declared state (Incremental mode).
- **`uniqueString()`** generates deterministic globally-unique names from the RG id.
-What you should do next to complete the POC:

In Azure DevOps, create ARM service connection named azure-arm-connection.
Create pipeline from azure-pipelines.yml.
Run with action = deploy.
Verify resources in RG rg-bicep-poc.
Run again with action = destroy to tear down.
Your infra files look good:

main.bicep
main.dev.bicepparam
storage.bicep
appservice.bicep
If you want, I can next help with one specific part:

Azure DevOps service connection setup
First deploy run troubleshooting
Add separate dev and prod parameter files
Add a manual approval gate before deploy
