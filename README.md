# CAPI Release

This is the [bosh release](http://bosh.io/docs/release.html) for Cloud Foundry's [Cloud Controller](https://github.com/cloudfoundry/cloud_controller_ng).

## Install binaries for running CCBridge unit tests

```
# Install ginkgo
go install github.com/onsi/ginkgo/ginkgo

# Install consul
if uname -a | grep Darwin; then os=darwin; else os=linux; fi
curl -L -o $TMPDIR/consul-0.5.2.zip "https://releases.hashicorp.com/consul/0.5.2/consul_0.5.2_${os}_amd64.zip"
unzip $TMPDIR/consul-0.5.2.zip -d $GOPATH/bin
rm $TMPDIR/consul-0.5.2.zip
```
