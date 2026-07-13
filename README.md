# truenas-acme-ionos
Script for TrueNAS ACME to communicate with IONOS DNS 

The script must be edited to add parameters:
- IONOS_PREFIX
- IONOS_SECRET
- LF (optional)

Add the ionos_dns.sh as a shell script to Credentials -> Certificates -> ACME DNS-Authenticators.  Use the "shell" as the Authenticator type, and the path to the script in Script field.
