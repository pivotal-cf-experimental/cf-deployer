# CF Deployer

[![Build Status](https://travis-ci.org/pivotal-cf-experimental/cf-deployer.png?branch=master)](https://travis-ci.org/pivotal-cf-experimental/cf-deployer)
[![Code Climate](https://codeclimate.com/repos/52cca2d369568023c40002bb/badges/644c6ea6c8435e9b1bca/gpa.png)](https://codeclimate.com/repos/52cca2d369568023c40002bb/feed)

## Building and installing gem locally

cf-deployer is not on Rubygems yet.
To install the gem from source:

```bash
$ bundle exec rake install
cf_deployer 0.3.1 built to pkg/cf_deployer-0.3.1.gem.
cf_deployer (0.3.1) installed.
```

# Commands

```bash
# --release-repo        => e.g. git@github.com:cloudfoundry/cf-release
# --release-name        => e.g. my-cf-release
# --deployments-repo    => e.g. git@github.com:my-org/my-deployments (this must contian a directory named <release name>)
# --deployment-name     => e.g. my-cf-deployment
```

## Using `cf_deploy_uploaded_release`

This command deploys the latest uploaded release on the targeted director for the given release name and deployment.

It is not yet possible to specify a particular release version.
`latest` is used, unless specifically overridden in the deployment manifest, manually.

```bash
$ cf_deploy_uploaded_release \
    --release-repo <release repository>  \
    --release-ref master \
    --release-name <release name> \
    --deployments-repo <deployments repository> \
    --deployment-name <deployment name> \
    --infrastructure {aws, vsphere, warden} # pick one
```

# Using `cf_deploy_create_release`

```bash
$ cf_deploy_create_release \
    --release-repo <release repository>  \
    --release-ref master \
    --release-name <release name>
```
