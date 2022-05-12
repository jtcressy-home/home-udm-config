# home-udm-config
Terraform & Scripts to configure my home UDM Pro routing appliance

## Bootstrapping

Terraform requires an SSH connection to the UDM Pro appliance. The following should be carried out manually:

1. UDM setup with unifi app completed
2. Configure a LAN network with a subnet matching the IP address configured in providers.tf for the remote provider
4. Enable ssh with a password and update the secret in Vault under the configured paths (see the data sources in providers.tf)
5. Run a tailscale client on the LAN network connected to the github org's tailnet and advertise a /32 route for the IP address configured in step 2
    - e.g.
      ```
      tailscale up --advertise-routes 192.168.20.1/32
      ```
6. Run the pipeline and hope all goes to plan

### Note about att-bypass
- Ensure the tls ca, cert and key exist in a vault secret at the configured path (see data sources in wpa_supplicant.tf)
- You MUST configure the WAN interface in the unifi UI to clone the mac address from the subject common name of the tls cert
  - tip: use openssl to find the common name e.g.
    ```
    # openssl x509 -in tls-cert.pem -text | grep CN
            Subject: C=US, O=ARRIS Group, Inc., CN=XX:XX:XX:XX:XX:XX/serialNumber=000AAA-XXXXXXXXXXXXXX
    ```
- During bootstrapping, connect the WAN port for the UDM to the existing ATT gateway LAN port(s) to gain basic internet access
- AFTER bootstrapping, you can connct the WAN port for the UDM to the ONT - optionally inspect the wpa supplicant logs to verify auth is working
  - also, you can disconnect/restore configuration for the temporary tailscale client as tailscale should be configured on the UDM with advertised routes that will allow tailnet devices to reach the UDM's LAN IP