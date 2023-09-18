# reciprocal-borrowing-dev-env

This repository provides a local environment, via Docker, for developing and
testing the Reciporical Borrowing application
(<https://github.com/umd-lib/reciprocal-borrowing>).

## Provided Applications

This environment provides configured instances of the following applications:

* OpenLDAP
* Shibboleth Identity Provider (IdP)
* Shibboleth Service Provider (SP)

## Development Environment Setup

### 1) Prerequisites

1.1) Edit the “/etc/hosts” file on the local workstation:

```zsh
sudo vi /etc/hosts
```

and add the following entries:

```text
127.0.0.1       shib-idp
127.0.0.1       borrow-local
```

### 2) Repository Setup

2.1) In a base directory, clone this repository:

```zsh
$ git clone git@github.com:umd-lib/reciprocal-borrowing-dev-env.git
```

2.2) In the same base directory, clone the "reciprocal-borrowing" repository:

```zsh
$ git clone git@github.com:umd-lib/reciprocal-borrowing.git
```

### 3) Docker Image Setup

3.1) Switch into the "reciprocal-borrowing-dev-en" and run the following command
     to build the "shib-sp-reciprocal-borrowing:latest" Docker image using
     Kubernetes:

```zsh
$ cd reciprocal-borrowing-dev-env
$ docker buildx build --no-cache --progress=plain --builder kube --platform linux/amd64 -t shib-sp-reciprocal-borrowing --load -f sp/Dockerfile sp/.
```

**Note:** This build takes approximately 10 minutes.

### 4) Docker stack setup

4.1) Start the Docker stack:

```zsh
$ docker compose up
```

4.2) Once the Docker stack has started, run a Bash shell in the "borrow-local"
     container:

```zsh
$ docker exec -it borrow-local /bin/bash
```

4.3) In the "borrow-local" container, run the following commands to install the
     gems needed for the Reciprocal Borrowing application:

```bash
$ cd /root/reciprocal-borrowing
$ bundle config set force_ruby_platform true
$ bundle config set --local path 'vendor/bundle'
$ bundle install
```

**Note:** Installing the gems (especially the "bootstrap-sass" gem) will take
approximately 20 minutes. The gems will be stored in the "vendor/bundle"
directory of the "reciprocal-borrowing" checkout, so they will still be present
even if the "borrow-local" Docker container restarts.

### 5) Accessing the application

5.1) To access the application, in a web browser, go to:

<https://borrow-local/>

The browser may display a warning message related to unsigned certificates.
Accept the self-signed cerificate, and the Reciprocal Borrowing home page will
be shown.

5.2) On the Reciprocal Borrowing home page, select any institution *except* for
     the "University of Maryland" as the lending instituion. The second
     Reciprocal Borrowing page will be shown.

5.3) On the second Reciprocal Borrowing page, select "University of Maryland" as
     the authenticating institution.

  After selecting the authenticating insitution, the browser may display a
  warning message related to unsigned certificates. Accept the self-signed
  cerificate, and the login page from the IdP will be shown.

5.4) On the login page, enter the username and password, and left-click the
    "Login" button.

5.5) The Reciprocal Borrowing result page will be shown indicating whether or
     not the user is authorized to borrow.

## Gem Installation

The Ruby gems are installed into a "vendor/bundle" directory of the Reciprocal
Borrowing application. This enables them to still be in place after restarting
the "borrow-local" container.

The gems are configured to use the "amd64" archictecture, and so are not
directly usable on an M-series laptop, outside of the Docker container.

## Docker Compose

The applications are set up using Docker Compose.

All application run on a Docker "reciprocal-borrowing-network" internal network.

## OpenLDAP

The OpenLDAP implementation uses the "bitnami/openldap" Docker image
(<https://hub.docker.com/r/bitnami/openldap>).

The OpenLDAP server runs on ports 1389 and 1636, and is available using the
"openldap" hostname.

### Authentication Credentials

The following authentication credentials are used to connect to the
OpenLDAP server:

| Username   | Password       |
| ---------- | -------------- |
| adminuser  | adminpassword |

### Custom Users

The OpenLdap instance reads in the LDIF files in the "ldap/ldif" directory.

The following users are available:

| Username   | Password       |
| ---------- | -------------- |
| customuser | custompassword |

### LDIF Files

The LDIF files in the "ldap/ldifs" directory provide the initial setup of the
OpenLDAP database. These files are only read the first time OpenLDAP starts.

To reset the OpenLDAP database from the LDIF files:

1) Stop Docker Compose:

```zsh
$ docker compose down
```

2) Delete the "reciprocal-borrowing-dev-env_openldap_data" Docker volume:

```zsh
$ docker volume rm reciprocal-borrowing-dev-env_openldap_data
```

3) Restart Docker Compose:

```zsh
$ docker compose up
```

### OpenLDAP Verfication

Verification that OpenLDAP is running can be done by running the following
command:

```zsh
$ ldapsearch -D "cn=admin,dc=example,dc=org" -W -p 1389 -h 127.0.0.1 -b "dc=example,dc=org" -s sub -x "(objectclass=*)"
```

When prompted, the password is `adminpassword`

## Shibboleth Identity Provider (IdP)

The Shibboleth Identity Provider (IdP) connects to the OpenLDAP server to
authenticate users and retrieve user attributes.

The IdP implementation uses the TIER Shibboleth IdP Docker Reference
implementation (see
<https://spaces.at.internet2.edu/display/TPWG/TIER+Shibboleth+IdP+-+Docker+Reference+Implementation>)
with additional information available at
<https://docs.google.com/document/d/17-0O3Tvty9PONL6wu4PiC6ZWramdyntXmOsq1UpD2tE/edit>.

### IdP Dockerfile and Configuration

The contents of the "idp" subdirectory were initially created using the
"tier/shibbidp_configbuilder_container" Docker image:

```zsh
$ docker run --interactive --tty -v $PWD:/output -e "BUILD_ENV=LINUX" tier/shibbidp_configbuilder_container

Enter the FQDN or IP address of your server: shib-idp
Enter the Scope for your IdP [shib-idp]: shib-idp

Enter the LDAP URL used for your IdP: ldap://openldap:1389

Enter the LDAP Base DN used for your LDAP Server: dc=example,dc=org

Enter the LDAP DN for the service account used by your IdP: cn=admin,dc=example,dc=org
Enter the password for the account just specified: adminpassword
```

### IdP File Modifications

The following files were modified to support the configuration expected by
Reciprocal Borrowing. The original version of the files have a ".dist"
extension.

#### ldap.properties

#### idp/config/shib-idp/conf/access-control.xml

This file was constructed from the “conf/access-control.xml” file in the stock
Docker image (when it runs for the first time), with the “AccessByAdminUser”
stanza uncommented, and the “customuser” added.

Also, the IP Address CIDR '0.0.0.0/0' was added to the "AccessByIPAddress"
stanza, to allow connections from any IP address.

#### idp/config/shib-idp/conf/attribute-resolver.xml

Modified to supply "eduPersonEntitlement" and "eduPersonScopedAffiliation"
attributes as static attributes, instead of from LDAP.

#### idp/config/shib-idp/metadata/idp-metadata.xml

Modified the IDP service endpoints to use port 1443.

#### idp/config/shib-idp/conf/metadata-providers.xml

Modified to look up metadata provider from the
"/opt/shibboleth-idp/conf/borrow-local.xml" file.

The "borrow-local.xml" file is generated by the Shibboleth SP (see below).

### IdP Verification

In a web browser go to

<https://127.0.0.1:1443/idp/profile/admin/hello>

Should be able to login using `customuser` with a password of `custompassword`.

## Shibboleth Service Provide (SP)/Reciprocal Borrowing

## Building the SP/Recirpocal Borrowing Docker image

On an M-series (Apple Silicon) laptop, the SP/Reciprocal Borrowing Docker
image *must* be built in using Kubernetes. This is because the Phusion Passenger
application server uses to connect Apache to Rails is only available in an
"amd64" version.

To build the "shib-sp-reciprocal-borrowing" Docker image:

```zsh
$ docker buildx build --no-cache --progress=plain --builder kube --platform linux/amd64 -t shib-sp-reciprocal-borrowing --load -f sp/Dockerfile sp/.
```

The "--load" flag ensure that the "shib-sp-reciprocal-borrowing" Docker image
is loaded to the local workstation, and *not* pushed to the Nexus.

## SP Dockerfile and Configuration

The contents of the "sp" directory were generated from the
"3.4.1_06122023_rocky8_multiarch" tag of the
<https://github.internet2.edu/docker/shib-sp.git> Git repository.

The ".git" subdirectory was then deleted.

```zsh
$ git clone https://github.internet2.edu/docker/shib-sp.git sp
$ cd sp
$ git checkout 3.4.1_06122023_rocky8_multiarch
$ rm -rf .git
```

## Generating the SP certificates and metadata

The IdP requires metadata identifying the SP that uses self-signed certificates
generated as part of the SP Docker container startup.

In the normal configuration, these certificates are rebuilt every time the
SP Docker image is built.

To simplify the setup of this environment, the SP Dockerfile was modified
to use fixed "sp-encrypt-key.pem" and "sp-encrypt-cert.pem" files.

### SP File Modifications

The following files were modified to support the configuration expected by
Reciprocal Borrowing. The original version of the files have a ".dist"
extension.

#### sp/container_files/shibboleth2.xml

This added file configures the SP to talk to the IdP.

#### sp/container_files/httpd/00-virtualhosts.conf

Modified the Apache/Phusion Passenger configuration to use the
"development_docker" Rails environment, and to enable the "Reciprocal Borrowing"
application to be placed in the "/root" directory of the SP container.

#### Self-signed certificate files

The following files were generated in an initial run of the stock SP Docker
image, and then copied from the running Docker container.

These files define the self-signed certificates:

* sp-encrypt-cert.pem
* sp-encrypt-key.pem
* sp-signing-cert.pem
* sp-signing-key.pem

The SP Dockerfile has been modified to use these files, in place of regenerating
the certificates on each build. This enables the metadata file provided to the
IdP to remain unchanged.

To regenerate these files (which should not be necessary):

1) Uncommnt the following lines in the "sp/Dockerfile":

```text
# RUN openssl req -new -nodes -newkey rsa:2048 -subj "/commonName=localhost.localdomain" -batch -keyout /etc/pki/tls/private/localhost.key -out localhost.csr
#RUN openssl x509 -req -days 1825 -in localhost.csr -signkey /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
```

2) Rebuild the "shib-sp-reciprocal-borrowing" (see the
   "Building the SP/Recirpocal Borrowing Docker image" section above.

3) Run the "shib-sp-reciprocal-borrowing" Docker image:

```zsh
$ docker run --rm --publish=443:443 --name borrow-local shib-sp-reciprocal-borrowing:latest
```

4) Retrieve the metadata for the IdP:

```zsh
$ curl --insecure https://borrow-local/Shibboleth.sso/Metadata > idp/config/shib-idp/conf/shib-sp.xml
```

5) Copy the following files:

```zsh
$ docker cp borrow-local:/etc/shibboleth/sp-encrypt-cert.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-encrypt-key.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-signing-cert.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-signing-key.pem sp/container_files/shibboleth/
```

6) Stop the "borrow-local" Docker container

## Reciprocal Borrowing

### Shibboleth SP changes


### sp/Dockerfile


## Helpful Commands

In the "borrow-local" Docker container:

### Restart Apache

```bash
$ supervisorctl restart httpd
```

### Restart Passenger/reciprocal-borrowing

```bash
$ passenger-config restart-app /root/reciprocal-borrowing
```
