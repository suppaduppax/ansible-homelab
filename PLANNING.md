# Planning

Current nodes:
- michael.home
- chidi.home
- eleanor.home

vCenter:
- photon-machine.home

## Needs
### Reusability
playbooks need to be able to be reused when run in different deployments
ie:
  - hosts: example_server

Use vm folders to distinguish between staging/production deployments.

vCenter structure can look as follows:
ansible_prod/
  example_server
ansible_stag/
  example_server

vmware_inventory plugin should then distinguish between which server to choose:
inventory/prod/hosts.vmware.yml   <-- filters vms in the 'ansible_prod' folder
inventory/stag/hosts.vmware.yml   <-- filters vms in the 'ansible_stag' folder

## Scenario 1
I want to deploy a test vm in chidi -
```
- hosts: localhost
  tasks:
  - name: Deploy Virtual Machine from template in content library with PowerON State
    community.vmware.vmware_content_deploy_template:
      hostname: '{{ vcenter_hostname | mandatory }}'
      username: '{{ vcenter_username | mandatory }}'
      password: '{{ vcenter_password | mandatory }}'
      template: '{{ vm_template | mandatory }}'
      content_library: '{{ content_library | default(omit) }}'
      datastore: '{{ datastore | mandatory }}'
      folder: '{{ vm_folder }}'
      datacenter: '{{ vm_datacenter | mandatory }}'
      name: '{{ vm_name | mandatory }}'
      state: '{{ vm_state }}'

- hosts: plex
  roles:
    - provisioning/ubuntu
    - plex/prereq
    - plex/install
    - plex/configure
```
Ansible should be able to run plays on 'plex' which can either be in the 
'staging' or 'production' folders inside vcenter


## folder structure
inventory/
  prod/
    group_vars/
      all/
    host_vars/
      host1/

  stag/
    group_vars/
      all/


# vars and shared_vars/shared_vault
Each group_vars and host_vars directory can contain one or more of the following:
```
  vars.yml
  vault.yml
  shared_vars.yml
  shared_vault.yml
```

| name | description
| ---- | -----------
| shared_vars.yml     | Contains vars specific to that group/host in that particular deployment. For instance, `deployment: prod` is specific to the deployment and can 
                 be defined inside the `group_vars/all` directory
| shared_vault.yml    | Similar to vars.yml but is encrypted using ansible-vault
| vars  | Contains vars that are shared between all deployments. For instance, `vcenter_hostname: photon-machine.home` can be defined inside of it as it
                 will not change between any deployments. This can defined inside the `group_vars/all` directory
| vault | Similar to shared_vars but is encrypted using ansible-vault

Virtually all vars in group_vars/host_vars should be viewable inside of shared_vars. For instance, if a var called `vcenter_vm_folder` exists and is different
between deployments, it should be defined inside `shared_vars.yml` and reference a private variable inside vars.yml with the prefix `deployment`.
```
shared_vars.yml
---
vcenter_vm_folder: "{{ deployment_vcenter_vm_folder }}"
```

```
vars.yml
---
deployment_vcenter_vm_folder: "/homelab/vm/production"
```

shared_vars.yml and shared_vault.yml are symlinked files and should be stored inside the `staging` inventory directory.
