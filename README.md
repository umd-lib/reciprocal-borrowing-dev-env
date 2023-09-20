# reciprocal-borrowing-dev-env

This repository provides a local environment, via Docker, for developing and
testing the Reciprocal Borrowing application
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

### 2) Application Setup

2.1) In a base directory, clone this repository:

```zsh
$ git clone git@github.com:umd-lib/reciprocal-borrowing-dev-env.git
```

2.2) In the same base directory, clone the "reciprocal-borrowing" repository:

```zsh
$ git clone git@github.com:umd-lib/reciprocal-borrowing.git
```

### 3) Running the Application

The following steps assume that a suitable Shibboleth SP Docker image has been
created, containing a Ruby version compatible with the Reciprocal Borrowing
application being developed. See below for information about creating
a Shibboleth SP Docker image.

3.1) Start the Docker stack:

```zsh
$ docker compose up
```

3.2) Once the Docker stack has started, run a Bash shell in the "borrow-local"
container:

```zsh
$ docker exec -it borrow-local /bin/bash
```

3.3) In the "borrow-local" container, run the following commands to install the
gems needed for the Reciprocal Borrowing application:

```bash
borrow-local$ cd /root/reciprocal-borrowing
borrow-local$ bundle config set force_ruby_platform true
borrow-local$ bundle config set --local path 'vendor/bundle'
borrow-local$ bundle install
```

---
**Note:** Installing the gems will take approximately 10-20 minutes, but are
stored in the "vendor" directory of the Reciprocal Borrowing application, so
the gems will still be available after stopping and restarting tje Shibboleth SP
"borrow-local"container.

The gems are configured to use the "amd64" architecture, and so are not
directly usable on an M-series laptop, outside of the Docker container.

---

3.2) Access the application in a web browser by
going to, go to:

<https://borrow-local/>

The browser may display a warning message related to unsigned certificates.
Accept the self-signed certificate, and (after a few 10s of seconds) the
Reciprocal Borrowing home page will be shown.

3.3) On the Reciprocal Borrowing home page, select any organization for
as the lending organization. The second Reciprocal Borrowing page will be shown.

3.4) On the second Reciprocal Borrowing page, select one of the other
organizations as the authenticating institution.

After selecting the authenticating organization, the browser may display a
warning message related to unsigned certificates. Accept the self-signed
certificate, and the login page from the IdP will be shown.

3.5) On the login page, enter the username and password, such as:

* Username: `is_eligible`
* Password: `password`

and left-click the "Login" button. See the "Custom Users" section below for
additional users and credentials.

5.5) The Reciprocal Borrowing result page will be shown indicating that the user
is able to borrow.

Development can be done in the "reciprocal-borrowing" directory on the local
workstation. The file changes will be automatically copied into the Shibboleth
SP Docker container.

## Helpful Commands

The following commands can be run in the Shibboleth SP "borrow-local" Docker
container, which can be accessed by running:

```zsh
$ docker exec -it borrow-local /bin/bash
```

### Restart Apache

To restart Apache after making changes to the Apache configuration, run:

```bash
borrow-local$ supervisorctl restart httpd
```

### Restart Passenger/reciprocal-borrowing

The "reciprocal-borrowing" repository can be edited on the local machine, and
the changes will be automatically propagated to the Docker container and
reflected in the running Rails application, as in normal Rails development.

Some Rails changes, such as changes to the configuration or internationalization
files require the Rails application to be restarted, which can be done by
running the following command (in the "borrow-local" Docker container):

```bash
borrow-local$ passenger-config restart-app /root/reciprocal-borrowing
```

**Note:** Normal Rails development changes (i.e., changes to the application
views and controllers) should be picked up automatically (as if running in the
local development environment).

## Known Issues

The following are known issues with this “reciprocal-borrow-dev-env”
implementation:

* The user identifying attributes from LDAP (“cn”, “sn”, “givenName”,
  “displayName”) are not passed to the Rails application by the
  Shibboleth SP. Therefore the “Name”, “Principal Name”, and “Identifier” on
  the Reciprocal Borrowing result page will all display “N/A”.

* The Apache in the “borrow-local” Shibboleth SP container runs as “root”, and
  hence the Phusion Passenger and “reciprocal-borrowing” application also run as
  “root”. This is perfectly fine for a local development setup, but it likely
  not ideal for a production deployment (which this repository is not intended
  to provide).

## Shibboleth SP Docker Image Setup

The "sp" subdirectory contains a snapshot of the
"3.4.1_06122023_rocky8_multiarch" branch of the  Shibboleth SP Docker image
setup configuration
(<https://github.internet2.edu/docker/shib-sp/tree/3.4.1_06122023_rocky8_multiarch>)

The "Dockerfile" from the snapshot has been modified to include Ruby and the
Phusion Passenger web application server.

The "docker-compose.yml" file has been modified to mount the local
"reciprocal-borrowing" directory into the container to enable local development.

The Shibboleth SP Docker image should be recreated whenever:

* The Ruby version used by the "reciprocal-borrowing" application is updated
* As needed, to keep up with any Shibboleth SP or Phusion Passenger version
  changes used in production.

The following instructions use that the Kubernetes "build" environment to
construct an "amd64" Docker image (which is currently necessary, as Phusion
Passenger does not have an "arm64" build).

For more information about setting up the Kubernetes "build" environment, see
<https://github.com/umd-lib/k8s/blob/main/docs/DockerBuilds.md> in Confluence.

1) Switch into the "reciprocal-borrowing-dev-env" directory:

```zsh
$ cd reciprocal-borrowing-dev-env
```

2) Run the following command to build the "shib-sp-reciprocal-borrowing:\<TAG>"
   Docker image where \<TAG> is the Docker image tag to create:

```zsh
$ docker buildx build --no-cache --progress=plain --builder kube  --load \
  --platform linux/amd64 -f sp/Dockerfile \
  -t docker.lib.umd.edu/shib-sp-reciprocal-borrowing:<TAG> sp/.
```

For example, if the \<TAG> is "ruby-3.2.2" than the command would be:

```zsh
$ docker buildx build --no-cache --progress=plain --builder kube  --load \
  --platform linux/amd64 -f sp/Dockerfile \
  -t docker.lib.umd.edu/shib-sp-reciprocal-borrowing:ruby-3.2.2 sp/.
```

This build takes approximately 10 minutes. The "--load" flag is used to ensure
that the resulting "shib-sp-reciprocal-borrowing" Docker image is loaded on the
local workstation, and *not* pushed to the Nexus.

---
**Note:** The version of Phusion Passenger is not "pinned" and is installed
via the "yum" package manager, so its version may differ over time. The
current Dockerfile configuration was derived from the instructions at
<https://www.phusionpassenger.com/docs/advanced_guides/install_and_upgrade/apache/install/oss/el8.html>.

The current recommendation is to label the Docker image using the Ruby version,
as that is the most likely reason for updating the Docker image.

---

3) After creating the Docker image, update the "borrow-local" container in the
   "docker-compose.yml" file to use the new image.

4) Test the image by running the Docker Compose stack. If everything is working,
   push the Docker image to the Nexus, using the following command
   (where \<TAG>) is the tag of the Docker image:

```zsh
$ docker push docker.lib.umd.edu/shib-sp-reciprocal-borrowing:<TAG>
```

For example, if the \<TAG> is "ruby-3.2.2", then the command would be:

```zsh
$ docker push docker.lib.umd.edu/shib-sp-reciprocal-borrowing:ruby-3.2.2
```

## Docker Compose

The applications are set up using Docker Compose.

All application run on a Docker "reciprocal-borrowing-network" internal network.

## OpenLDAP

The OpenLDAP implementation uses a stock "bitnami/openldap" Docker image
(<https://hub.docker.com/r/bitnami/openldap>) pulled from Docker Hub.

The OpenLDAP server runs on ports 1389 and 1636, and is available using the
"openldap" hostname.

### Authentication Credentials

The following authentication credentials are used to connect to the
OpenLDAP server:

| Username   | Password       |
| ---------- | -------------- |
| adminuser  | adminpassword  |

### Custom Users

The OpenLdap instance reads in the LDIF files in the "ldap/ldif" directory.

The following users are available:

| Username      | Password | Note                                        |
| ------------- | -------- | ------------------------------------------- |
| is_eligible   | password | This user is eligible for borrowing         |
| not_eligible  | password | This user is **not** eligible for borrowing |

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

### OpenLDAP Verification

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

The IdP Docker image in built as part of the Docker Compose start up, utilizing
the configuration files present in the "idp" subdirectory.

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

After modifying any of the IdP configuration files, delete the existing
"reciprocal-borrowing-dev-env-shib-idp" Docker image, to have the IdP
automatically rebuilt with the changes:

```zsh
$ docker image rm reciprocal-borrowing-dev-env-shib-idp
```

#### idp/config/shib-idp/conf/access-control.xml

The IP Address CIDR '0.0.0.0/0' was added to the "AccessByIPAddress"
stanza, to allow connections from any IPv4 address.

#### idp/config/shib-idp/conf/attribute-filter.xml

Added a "reciprocal_borrowing_filter" AttributeFilterPolicy that only releases
the "eduPersonEntitlement" attribute for the "is_eligible" user.

#### idp/config/shib-idp/conf/attribute-resolver.xml

Modified to supply "eduPersonEntitlement" attribute as a static attribute,
instead of from LDAP.

An "eduPersonEntitlement" attribute with a value of
`https://borrow.btaa.org/reciprocalborrower` indicates that a user is eligible
to borrow.

The "reciprocal_borrowing_filter" AttributeFilterPolicy in
"idp/config/shib-idp/conf/attribute-filter.xml" only releases the attribute for
the "is_eligible" user.

#### idp/config/shib-idp/metadata/idp-metadata.xml

Modified the IDP service endpoints to use port 1443.

#### idp/config/shib-idp/conf/ldap.properties

Modified to support connecting to the OpenLDAP container, and to reflect the
user attributes produced by LDAP.

#### idp/config/shib-idp/conf/metadata-providers.xml

Modified to look up metadata provider from the
"/opt/shibboleth-idp/conf/borrow-local.xml" file.

The "borrow-local.xml" file is generated by the Shibboleth SP (see below).

### IdP Verification

In a web browser go to

<https://shib-idp:1443/idp/profile/admin/hello>

Should be able to login using `is_eligible` with a password of `password`.

## Shibboleth Service Provider (SP)/Reciprocal Borrowing

## SP Dockerfile and Configuration

The contents of the "sp" directory were generated from the
"3.4.1_06122023_rocky8_multiarch" branch of the
<https://github.internet2.edu/docker/shib-sp.git> Git repository,
specifically Git hash
"[1b51145b510b11380702c36d7b163a1b9dfbca3f](https://github.internet2.edu/docker/shib-sp/commit/1b51145b510b11380702c36d7b163a1b9dfbca3f)".

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

#### sp/Dockerfile

A section was appended to the end of the stock Dockerfile to install
Phusion Passenger and Ruby.

#### sp/container_files/shibboleth/attribute-map.xml

Modified to return the "eduPersonEntitlement" as "eduPersonEntitlement",
instead of as "entitlement".

The "eduPersonEntitlement" key is what is used by Reciprocal Borrowing to
identify users authorized to borrow.

#### sp/container_files/shibboleth2.xml

This added file configures the SP to talk to the IdP. The original file
(as renamed to "shibboleth2.xml.dist") was generated by building and running the
"sp/Dockerfile" without a "shibboleth2.xml" file once, and then copying the
file in the "/etc/shibboleth/" directory.

#### sp/container_files/httpd/00-virtualhosts.conf

Modified the Apache/Phusion Passenger configuration to use the
"development_docker" Rails environment, and to enable the "Reciprocal Borrowing"
application to be placed in the "/root" directory of the SP container.

#### Self-signed certificate files

The following self-signed certificates files were generated in an initial run of
the stock SP Docker image, and then copied from the running Docker container:

* sp-encrypt-cert.pem
* sp-encrypt-key.pem
* sp-signing-cert.pem
* sp-signing-key.pem

The SP Dockerfile has been modified to use these files, in place of regenerating
the certificates on each build. This enables the metadata file provided to the
IdP to remain unchanged.

To regenerate these files (which should not be necessary):

1) Delete the existing "sp-*-cert.pem" files:

```zsh
$ cd reciprocal-borrowing-dev-env
$ rm sp/container_files/shibboleth/sp-encrypt-cert.pem
$ rm sp/container_files/shibboleth/sp-encrypt-key.pem
$ rm sp/container_files/shibboleth/sp-signing-cert.pem
```

2) Rebuild the "shib-sp-reciprocal-borrowing" Docker image:

```zsh
$ docker buildx build --no-cache --progress=plain --builder kube  --load \
  --platform linux/amd64 -f sp/Dockerfile \
  -t shib-sp-reciprocal-borrowing:latest sp/.
```

**Note:** The resulting image should *not* be pushed to the Nexus.

3) Run the "shib-sp-reciprocal-borrowing" Docker image:

```zsh
$ docker run --rm --publish=443:443 --name borrow-local shib-sp-reciprocal-borrowing:latest
```

4) Retrieve the Shibboleth SP metadata and copy into the "idp" directory, so
   that it available to the IdP:

```zsh
$ curl --insecure https://borrow-local/Shibboleth.sso/Metadata > idp/config/shib-idp/conf/shib-sp.xml
```

5) Copy the following files into the "sp" directory, so that they will be used
   by the SP:

```zsh
$ docker cp borrow-local:/etc/shibboleth/sp-encrypt-cert.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-encrypt-key.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-signing-cert.pem sp/container_files/shibboleth/
$ docker cp borrow-local:/etc/shibboleth/sp-signing-key.pem sp/container_files/shibboleth/
```

6) Stop the "borrow-local" Docker container.

7) If necessary, delete the existing IdP Docker image:

```zsh
$ docker image rm reciprocal-borrowing-dev-env-shib-idp
```

8) Rebuild the Shibboleth SP Docker image using the instructions in the
   "Shibboleth SP Docker Image Setup" section above, and push to the Nexus.
