# Terraform Module

## Publish to the Terraform registry

1. ROTATE TFC TOKEN NOW (exposed in chat)
   app.terraform.io → User Settings → Tokens → Delete → Create new

2. Re-create module in TFC Private Registry
   app.terraform.io → Registry → Publish → Module
   → VCS: GitHub → Repo: nnthanh101/terraform-aws
   → Module path: modules/iam-identity-center

3. git tag v1.0.0 && git push origin v1.0.0
   (triggers registry-publish.yml → validate → test → release → TFC ingestion)

4. Monitor pipeline: GitHub Actions → registry-publish → SLO <10min

5. Post-publish verification (ADR-019):
  curl -s --header "Authorization: Bearer $TFC_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/oceansoft/registry-modules/private/oceansoft/iam-identity-center/aws/1.0.0" | jq .status

6. Verify module exists
  curl -s --header "Authorization: Bearer $TFC_TOKEN" "https://app.terraform.io/api/v2/organizations/oceansoft/registry-modules/private/oceansoft/iam-identity-center/aws" | jq .

7. Delete module
curl -s --header "Authorization: Bearer $TFC_TOKEN" --header "Content-Type:application/vnd.api+json" --request DELETE "https://app.terraform.io/api/v2/organizations/oceansoft/registry-modules/private/oceansoft/iam-identity-center/aws"

---

