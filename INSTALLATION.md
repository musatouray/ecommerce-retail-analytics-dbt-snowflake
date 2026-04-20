# Installation Guide

## Prerequisites

- Python 3.12 (dbt doesn't support Python 3.13+ yet)
- [uv](https://docs.astral.sh/uv/) - Fast Python package manager
- Snowflake account with key-pair authentication
- Kaggle account (for data download)

## 1. Clone the Repository

```bash
git clone https://github.com/musatouray/ecommerce-retail-analytics-dbt-snowflake.git
cd ecommerce-retail-analytics-dbt-snowflake/ecommerce-retail-analytics
```

## 2. Install Python 3.12 and Dependencies

```bash
# Install Python 3.12 via uv
uv python install 3.12

# Create virtual environment with Python 3.12
uv venv --python 3.12

# Install dependencies
uv sync
```

## 3. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env with your credentials
```

Required environment variables:

| Variable | Description |
|----------|-------------|
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier |
| `SNOWFLAKE_USER` | Your Snowflake username |
| `SNOWFLAKE_DATABASE` | Target database name |
| `SNOWFLAKE_WAREHOUSE` | Compute warehouse name |
| `SNOWFLAKE_SCHEMA` | Target schema name |
| `SNOWFLAKE_ROLE` | Your Snowflake role |
| `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` | Passphrase for your private key (if encrypted) |
| `KAGGLE_USERNAME` | Your Kaggle username |
| `KAGGLE_KEY` | Your Kaggle API key |

## 4. Set Up Snowflake Key-Pair Authentication

Key-pair authentication is more secure than password authentication and bypasses MFA prompts.

### Generate RSA Key Pair

```bash
# Create directory for keys
mkdir ~/.snowflake
cd ~/.snowflake

# Generate private key (without passphrase)
openssl genrsa -out rsa_key_temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -in rsa_key_temp.pem -out rsa_key.p8 -nocrypt
rm rsa_key_temp.pem

# Or with passphrase (more secure)
openssl genrsa -out rsa_key_temp.pem 2048
openssl pkcs8 -topk8 -inform PEM -in rsa_key_temp.pem -out rsa_key.p8 -v2 aes256
rm rsa_key_temp.pem

# Generate public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

### Assign Public Key to Snowflake User

1. View your public key:
   ```bash
   cat ~/.snowflake/rsa_key.pub
   ```

2. Copy the key content (remove `-----BEGIN PUBLIC KEY-----` and `-----END PUBLIC KEY-----`, join into one line)

3. In Snowflake, run:
   ```sql
   ALTER USER YOUR_USERNAME SET RSA_PUBLIC_KEY='your_public_key_content_here';
   ```

4. Verify it worked:
   ```sql
   DESC USER YOUR_USERNAME;
   ```
   Look for `RSA_PUBLIC_KEY_FP` — it should show a fingerprint.

## 5. Configure dbt Profile

Create `~/.dbt/profiles.yml`:

```yaml
ecommerce_retail_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      threads: 16
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      private_key_path: ~/.snowflake/rsa_key.p8
      private_key_passphrase: "{{ env_var('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE') }}"  # if using passphrase
```

## 6. Verify Connection

```bash
# Activate virtual environment
# Windows PowerShell:
.venv\Scripts\Activate.ps1
# Linux/Mac:
source .venv/bin/activate

# Load environment variables and test
cd dbt
dbt debug
```

You should see:
```
All checks passed!
```

## Troubleshooting

### Python version errors
dbt currently supports Python 3.9 - 3.12. If you see import errors, ensure you're using Python 3.12:
```bash
uv venv --python 3.12
uv sync
```

### MFA required error
This means you need to set up key-pair authentication (Step 4) instead of password authentication.

### Environment variables not found
Make sure to load your `.env` file before running dbt:
```bash
# Linux/Mac
set -a && source .env && set +a

# Windows PowerShell
Get-Content .env | ForEach-Object {
  if ($_ -match '^([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
  }
}
```
