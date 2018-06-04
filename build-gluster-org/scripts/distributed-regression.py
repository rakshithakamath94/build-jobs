#!/usr/bin/env python
import subprocess
import os
from ansible.parsing.dataloader import DataLoader
from ansible.vars.manager import VariableManager
from ansible.inventory.manager import InventoryManager


def get_ansible_host_ip():
   loader = DataLoader()
   inventory = InventoryManager(loader=loader, sources='hosts')
   variable_manager = VariableManager(loader=loader, inventory=inventory)
   hostnames = []
   for host in inventory.get_hosts():
       hostnames.append(variable_manager.get_vars(host=host))
   ip='\t'.join([str(i['ansible_host']) for i in hostnames])
   return ip


def main():
    ip = get_ansible_host_ip()
    key_path = os.path.join(os.environ.get('WORKSPACE'), 'key')
    subprocess.call('/extras/distributed-testing/distributed-test.sh '
                    '--hosts {0} --id_rsa {1}'.format(ip, key_path))


main()
