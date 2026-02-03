# PowerShell script to generate backend.tf from bootstrap outputs

# $BootstrapDir = ".\bootstrap"
$BackendFile = ".\backend.tf"

# Get outputs from bootstrap
# Push-Location $BootstrapDir
$BucketName = terraform output -raw s3_bucket_name
$DynamoDBTable = terraform output -raw dynamodb_table_name
$Region = try { terraform output -raw region } catch { "us-west-2" }
Pop-Location

# Generate backend.tf content
$BackendContent = @"
terraform {
  backend "s3" {
    bucket         = "$BucketName"
    key            = "infrastructure/dev/terraform.tfstate"
    region         = "$Region"
    encrypt        = true
    # dynamodb_table = "$DynamoDBTable"
    use_lockfile   = true
  }
}
"@

# Write to file
$BackendContent | Out-File -FilePath $BackendFile -Encoding UTF8

Write-Host "Generated $BackendFile with:"
Write-Host "  Bucket: $BucketName"
Write-Host "  DynamoDB Table: $DynamoDBTable"
Write-Host "  Region: $Region"