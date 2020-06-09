# cookbook

This step builds a Vagrant box from an Fedora ISO. It uses KVM and Qemu for that. The newly created box will be uploaded to Vagrant cloud. You need to have an account for that.

export your Vagrant Cloud Key: export VAGRANT_CLOUD_TOKEN asd123
Create a Vagrant box in Vagrant Cloud. In my case: mkaesz_hc/fedora32. The box name must match the name in build.json.
Build the box: packer build -var serial=$(tty) build.json
