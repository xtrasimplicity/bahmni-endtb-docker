# bahmni-endtb-docker
Bahmni EndTB running on Docker

# Usage
*To be completed...*

## Secrets
In a production environment, you will likely want to override the default database and application passwords and use something more secure. To do this, you can mount a file at `/run/secrets.env` within the container which sets the desired credentials.

**Note**: As this file is `sourced` via Bash, this file must contain correct bash syntax. Consequently, you could also implement environment-specific checks and set different variable values depending on the environment, etc, using Bash.

If a `secrets.env` file does not exist, or if a variable has not been defined, the default Bahmni credentials will be used for that specific variable.

```shell
# Example secrets.env file
MYSQL_ROOT_PASSWORD=
OPENMRS_DB_PASSWORD=
REPORTS_DB_PASSWORD=
OPENELIS_DB_PASSWORD=

OPENMRS_REPORTS_USER_PASSWORD=
```