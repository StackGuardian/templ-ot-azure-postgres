# Integration tests: deploy real resources, check them, then destroy them.
# This costs money and needs cloud credentials.
# Run: tofu test -test-directory=tests/integration
# Test case catalog: tests/README.md

variables {
  name_prefix = "itest"
  tags = {
    Purpose = "integration-test"
  }
}

run "deploy" {
  command = apply
}

# I-01, I-02, I-03
run "server_is_private_and_secret_exists" {
  module {
    source = "./tests/integration/db-check"
  }

  variables {
    server_name         = run.deploy.server_name
    resource_group_name = run.deploy.resource_group_name
    key_vault_id        = run.deploy.key_vault_id
  }

  assert {
    condition     = output.fqdn != ""
    error_message = "The server was not created."
  }

  assert {
    condition     = !output.public_network_access_enabled
    error_message = "Public network access must be disabled."
  }

  assert {
    condition     = contains(output.secret_names, run.deploy.admin_password_secret_name)
    error_message = "The admin password secret does not exist in Key Vault."
  }
}
