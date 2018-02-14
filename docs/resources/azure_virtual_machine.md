---
title: About the azure_virtual_machine Resource
---

# azure_virtual_machine

Use the `azure_virtual_machine` InSpec audit resource to ensure that a Virtual Machine has been provisionned correctly.

## References

- [Azure Ruby SDK - Resources](https://github.com/Azure/azure-sdk-for-ruby/tree/master/management/azure_mgmt_resources)

## Syntax

The name of the machine and the resourece group are required as properties to the resource.

```ruby
describe azure_virtual_machine(group_name: 'MyResourceGroup', name: 'MyVM') do
  its('property') { should eq 'value' }
end
```

where

* Resource Parameters
  * `MyVm` is the name of the virtual machine as seen in Azure. (It is **not** the hostname of the machine)
  * `MyResourceGroup` is the name of the resource group that the machine is in.
* `property` is one of
  - [`type`](#type)
  - [`location`](#location)
  - [`name`](#name)
  - [`publisher`](#publisher)
  - [`offer`](#offer)
  - [`sku`](#sku)
  - [`os_type`](#"os_type")
  - [`os_disk_name`](#os_disk_name)
  - [`have_managed_osdisk`](#have_managed_osdisk?)
  - [`caching`](#caching)
  - `create_option`
  - `disk_size_gb`
  - `have_data_disks`
  - `data_disk_count`  
  - `storage_account_type`
  - `vm_size`
  - `computer_name`
  - `admin_username`
  - `have_nics`
  - `nic_count`
  - `connected_nics`
  - `have_password_authentication`
  - `password_authentication?`
  - `have_custom_data`
  - `custom_data?`
  - `have_ssh_keys`
  - `ssh_keys?`
  - `ssh_key_count`
  - `ssh_keys`
  - `have_boot_diagnostics`
  - `boot_diagnostics_storage_uri`
* `value` is the expected output from the matcher

The options that can be passed to the resource are as follows.

| Name        | Description                                                                                                         | Required | Example                           |
|-------------|---------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------|
| group_name: | Azure Resource Group to be tested                                                                                   | yes      | MyResourceGroup                   |
| name:       | Name of the Azure resource to test                                                                                  | no       | MyVM                              |
| apiversion: | API Version to use when interrogating the resource. If not set then the latest version for the resoure type is used | no       | 2017-10-9                         |

These options can also be set using the environment variables:

 - `AZURE_RESOURCE_GROUP_NAME`
 - `AZURE_RESOURCE_NAME`
 - `AZURE_RESOURCE_API_VERSION`

When the options have been set as well as the environment variables, the environment variables take priority.

For example:

```ruby
describe azure_virtual_machine(group_name: 'Inspec-Azure', name: 'Linux-Internal-VM') do
  its('os_type') { should eq 'Linux' }
  it { should have_boot_diagnostics }
end
```

## Testers

There are a number of built in comparison operrtors that are available to test the result with an expected value.

For information on all that are available please refer to the [Inspec Matchers Reference](https://www.inspec.io/docs/reference/matchers/) page.

## Properties

This InSpec audit resource has the following properties that can be tested:

### type

THe Azure Resource type. For a virtual machine this will always return `Microsoft.Compute/virtualMachines`

### location

Where the machine is located

```ruby
its('location') { should eq 'westeurope' }
```

### name

Name of the Virtual Machine in Azure. Be aware that this is not the computer name or hostname, rather the name of the machine when seen in the Azure Portal.

### publisher

The publisher of the image from which this machine was built.

This will be `nil` if the machine was created from a custom image.

### offer

The offer from the publisher of the build image.

This will be `nil` if the machine was created from a custom image.

### sku

The item from the publisher that was used to create the image.

This will be `nil` if the machine was created from a custom image.

### os_type

Test that returns the classification in Azure of the operating system type. Ostensibly this will be either `Linux` or `Windows`.

### os_disk_name

Return the name of the operating system disk attached to the machine.

### have_managed_osdisk

Determine if the operating system disk is a Managed Disks or not.

This test can be used in the following way:

```ruby
it { should have_managed_osdisk }
```

### caching

Returns the type of caching that has been set on the operating system disk.

### create_option

When the operating system disk is created, how it was created is set as an property. This property returns how the disk was created.

### disk_size_gb

Returns the size of the operating system disk.

### have_data_disks

Denotes if the machine has data disks attached to it or not.

```ruby
it { should have_data_disks }
```

### data_disk_count

Return the number of data disks that are attached to the machine

### storage_account_type

This provides the storage account type for a machine that is using managed disks for the operating system disk.

### vm_size

The size of the machine in Azure

```ruby
its('vm_size') { should eq 'Standard_DS2_v2' }
```

### computer_name

The name of the machine. This is what was assigned to the machine during deployment and is what _should_ be returned by the `hostname` command.

### admin_username

The admin username that was assigned to the machine

NOTE: Azure does not allow the use of `Administrator` as the admin username on a Windows machine

## have_nics

Returns a boolean to state if the machine has NICs connected or not.

This has can be used in the following way:

```ruby
it { should have_nics }
```

### nic_count

The number of network interface cards that have been attached to the machine

### connected_nics

This returns an array of the NIC ids that are connected to the machine. This means that it possible to check that the machine has the correct NIC(s) attached and thus on the correct subnet.

```ruby
its('connected_nics') { should include /Inspec-NIC-1/ }
```

Note the use of the regular expression here. This is because the NIC id is a long string that contains the subscription id, resource group, machine id as well as other things. By using the regular expression the NIC can be checked withouth breaking this string up. It also means that other tests can be performed.

An example of the id string is `/subscriptions/1e0b427a-d58b-494e-ae4f-ee558463ebbf/resourceGroups/Inspec-Azure/providers/Microsoft.Network/networkInterfaces/Inspec-NIC-1`

### have_password_authentication

Returns a boolean to denote if the machine is accessible using a password.

```ruby
it { should have_password_authentication }
```

### password_authentication?

Boolean to state of password authentication is enabled or not for the admin user.

```ruby
its('password_authentication?') { should be false }
```

This only applies to Linux machines and will always return `true` on Windows.

### have_custom_data

Returns a boolean stating if the machine has custom data assigned to it.

```ruby
it { should have_custom_data }
```

### custom_data?

Boolean to state if the machine has custom data or not

```ruby
its('custom_data') { should be true }
```

### have_ssh_keys

Boolean to state if the machine has SSH keys assigned to it

```ruby
it { should have_ssh_keys }
```

For a Windows machine this will always be false.

### ssh_keys?

Boolean to state of the machine is accessible using SSH keys

```ruby
its('ssh_keys?') { should be true }
```

### ssh_key_count

Returns how many SSH keys have been applied to the machine.

This only applies to Linux machines and will always return `0` on Windows.

### ssh_keys

Returns an array of the keys that are assigned to the machine. This is check if the correct keys are assigned.

Most SSH public keys have a signature at the end of them that can be tested. For example:

```ruby
its('ssh_keys') { should include /azure@inspec.local/ }
```

### boot_diagnostics?

Boolean test to see if boot diagnostics have been enabled on the machine

```ruby
it { should have_boot_diagnostics }
```

### boot_diagnostics_storage_uri

If boot diagnostics are enabled for the machine they will be saved in a storage account. This method returns the URI for the storage account.

```ruby
its('boot_diagnostics_storage_uri') { should match 'ghjgjhgjg' }
```
## Tags

It is possible to test the tags that have been assigned to the resource. There are a number of properties that can be called to check that it has tags, that it has the correct number and that the correct ones are assigned.

### have_tags

This is a simple test to see if the machine has tags assigned to it or not.

```ruby
it { should have_tags }
```

### tag_count

Returns the number of tags that are assigned to the resource

```ruby
its ('tag_count') { should eq 2 }
```

### tags

It is possible to check if a specific tag has been set on the resource.

```ruby
its('tags') { should include 'Owner' }
```

### xxx_tag

To get the value of the tag, a number of tests have been craeted from the tags that are set.

For example, if the following tag is set on a resource:

| Tag Name | Value |
|----------|-------|
| Owner | Russell Seymour |

Then a test is available called `Owner_tag`.

```ruby
its('Owner_tag') { should cmp 'Russell Seymour' }
```

Note: The tag name is case sensitive which makes the test case sensitive. E.g. `owner_tag` does not equal `Owner_tag`.

## Examples

The following examples show how to use this InSpec audit resource.

Please refer the integration tests for more in depth examples:

 - [Virtual Machine External VM](../../test/integration/verify/controls/virtual_machine_external_vm.rb)
 - [Virtual Machine Internal VM](../../test/integration/verify/controls/virtual_machine_internal_vm.rb)

### Test that the machine was built from a Windows image

```ruby
describe azure_virtual_machine(name: 'Windows-Internal-VM', group_name: 'Inspec-Azure') do
  its('publisher') { should eq 'MicrosoftWindowsServer' }
  its('offer') { should eq 'WindowsServer' }
  its('sku') { should eq '2012-R2-Datacenter' }
end
```

### Ensure the machine is in the correct location

```ruby
describe azure_virtual_machine(name: 'Linux-Internal-VM', resource_group: 'Inspec-Azure') do
  its('location') { should eq 'westeurope' }
end
