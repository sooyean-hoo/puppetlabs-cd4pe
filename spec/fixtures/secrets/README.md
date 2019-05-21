# Secrets for CD4PE acceptance & scale testing

Before running the CD4PE test environment setup tasks you will need to add the relevant credentials to this secrets directory. These credentials will be used in the test environment setup process.

1. Add the private key found in the CD4PE 1Password vault under the title `CD4PE Acceptance Test Control Repo Deploy Key` and place in this secrets directory with the name `cd4pe-acceptance-control-repo`. This key is the deploy key used for the acceptance test control repo.
2. Add the private key found in the CD4PE 1Password vault under the title `CD4PE Acceptance Test Module Deploy Key
` and place in this secrets directory with the name `cd4pe-acceptance-module`.
3. Optional. If running the test environment with the CD4PE storage provider set to 's3' then you will need to place the shared AWS key pair in this secrets directory with the name `cd4pe-acceptance-s3-creds.csv`. These credentials can be found in the CD4PE 1Password vault under the title `CD4PE Acceptance Test AWS S3 credentials`. Make sure that all the CSV data is copied into the file including the CSV headers.