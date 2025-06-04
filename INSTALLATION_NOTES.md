## ⚠️ Known GCP Organization Policy Constraints

### 1. Restriction on `allUsers` IAM Role Assignment

- **Issue**: Some GCP organizations enforce a policy that **prevents assigning roles to `allUsers`**.
- **Impact**: This breaks public access to the application via a normal HTTPS URL.
- **Context**: The app is protected behind **Identity-Aware Proxy (IAP)**, so allowing public URL access does **not** expose it to unauthenticated users.
- **Resolution**:
  - If possible, work with your GCP organization admin to allow `allUsers` to be granted to this specific project.
  - Since IAP is enabled, this configuration is still secure.

---

### 2. Restriction on Global Secret Creation

- **Issue**: Organization policy may **block creation of global (multi-region) secrets** in Secret Manager.
- **Impact**: The application's deployment fails if secrets are not created with a regional scope.
- **Resolution**:
  - If possible, work with your GCP organization admin to allow the creation of global secrets in this specific project.

For help or updates to these notes, please reach us at team@automatearmy.com