Components communicating with CC via its internal API (for example: Loggregator, BBS, and TPS) will do so over mutual TLS.
This is part of an effort to have all Cloud Foundry internal traffic be done over mutual TLS in lieu of basic auth.
The CC and other components must now be configured with several new certificates to establish these mTLS connections.
For most deployments, use a shared CA between CF and Diego deployments.

# Generating the shared CA certificate:

## For an existing deployment

We will use the CA cert configured for Diego's deployment to populate
`properties.cc.mutual_tls.ca_cert` and `properties.capi.tps.cc.ca_cert`.

## For new deployments

Please run `./cf-release/scripts/generate-cf-diego-certs`. This script will create a directory called cf-diego-certs.
Within this directory will be a CA, to be shared between your cf-release and diego-release deployments.


Contents of file                            | Property
------------------------------------------- | ---------
`cf-release/cf-diego-certs/cf-diego-ca.crt` | `properties.cc.mutual_tls.ca_cert`
`cf-release/cf-diego-certs/cf-diego-ca.crt` | `properties.capi.tps.cc.ca_cert`

# Generating the Cloud Controller Server certificate

## For an existing deployment

Given an existing CA, with the .crt and .key files found in `/path/to/CA`, we can generate a signing request and sign it with that CA

```
$ certstrap --depot-path /path/to/CA request-cert --passphrase '' --common-name cloud-controller-ng.service.cf.internal
$ certstrap --depot-path /path/to/CA sign cloud-controller-ng.service.cf.internal --CA <CA NAME>
```

Contents of file                                          | Property
--------------------------------------------------------- | ---------
`/path/to/CA/cloud-controller-ng.service.cf.internal.crt` | `properties.cc.mutual_tls.public_cert`
`/path/to/CA/cloud-controller-ng.service.cf.internal.key` | `properties.cc.mutual_tls.private_key`

## For a new deployment

If you generated a cert above using `./cf-release/scripts/generate-cf-diego-certs`:

Contents of file                                 | Property
-----------------------------------------------  | ---------
`cf-release/cf-diego-certs/cloud-controller.crt` | `properties.cc.mutual_tls.public_cert`
`cf-release/cf-diego-certs/cloud-controller.key` | `properties.cc.mutual_tls.private_key`

# Generating the TPS client certificate

The `./diego-release/scripts/generate-tps-certs` script will guide you on how to generate the values.
Use the same CA as the steps above.

Contents of file                                 | Property
------------------------------------------------ | ---------
`diego-release/diego-certs/tps-certs/client.crt` | `properties.capi.tps.cc.client_cert`
`diego-release/diego-certs/tps-certs/client.key` | `properties.capi.tps.cc.client_key`.

If you run into trouble, please feel free to reach out to us on [slack](https://cloudfoundry.slack.com/messages/capi/).
