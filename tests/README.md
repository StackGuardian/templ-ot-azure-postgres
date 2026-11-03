# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.8 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

## Run locally

```bash
tofu init
tofu test -test-directory=tests/unit
tofu test -test-directory=tests/integration   # needs cloud credentials
```

## Test cases

| ID | Level | Description | Status |
|---|---|---|---|
| U-01 | Unit | Default variables produce a valid plan with all default tags | done |
| U-02 | Unit | Invalid `name_prefix` is rejected | done |
| U-03 | Unit | Custom `tags` are merged with the default tags | done |
| U-04 | Unit | Public network access is disabled | done |
| U-05 | Unit | Server uses the delegated subnet and the private DNS zone linked to the VNet | done |
| U-06 | Unit | `require_secure_transport` is `on` with minimum TLS 1.2 | done |
| U-07 | Unit | Admin password only through write-only arguments, secret has an expiry date, Key Vault uses RBAC | done |
| U-08 | Unit | Backup retention is at least 7 days | done |
| U-09 | Unit | Backup retention below 7 days is rejected | done |
| U-10 | Unit | Server logs and Key Vault audit logs go to Log Analytics, connections are logged | done |
| I-01 | Integration | Server is created and has an FQDN | done |
| I-02 | Integration | Public network access is disabled on the deployed server | done |
| I-03 | Integration | Admin password secret exists in Key Vault (value is not read) | done |

Integration tests are written but have not run against a real cloud account yet.
