# Creating Timescale Services with Terraform

## How to run

```bash
terraform init

# use keys and project ID from your existing project
export TF_VAR_ts_access_key=01JR8823FVNHNQZY0TJBXXXXX
export TF_VAR_ts_secret_key=j68Od78cDOKJItUCnWoC7PQPkGSkIpbPaaU2aquwkErrqIYgB3xCmAxxxXXXxx
export TF_VAR_ts_project_id=ocssxxxx

terraform validate  

terraform apply

```

Terraform would not display sensitive values (password, psql connection string). You can revial these after successful `terraform apply` with:

```bash
terraform output timescale_service_psql
```

## References

- [Timescale terraform provider](https://registry.terraform.io/providers/timescale/timescale/latest/docs)
- [Timescale documentation](https://docs.timescale.com/use-timescale/latest/integrations/terraform/)