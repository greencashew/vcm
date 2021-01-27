# VirtualBox Cluster Manager

Script make creation and managing VirtualBox machines cluster easier.

## Requirements

- Linux base system
- VirtualBox

## Usage

```bash
➜  vbox_cluster git:(master) ✗ ./vcm.sh help      
Usage:
 ./vcm.sh [parameters]
     start behavior                                             Start VM stack defined in file, possible behaviors: headless, separate, gui
     start behavior destinationVmName                           Start specific VM
        start h                                                    Start vm stack in headless state
     stop behavior                                              Stop cluster with specific behavior: acpi, savestate, poweroff, pause
                                                                If machine not turning within 40 sec script ask about killing VirtualMachine
     stop behavior destinationVmName                            Stop specific virtualmachine
        stop a                                                     Stop vm stack with acpi power button
     clone "sourceVmName" "destinationVmName"                   Clone specific vm one time, you can only clone already registered vm
     clone "sourceVmName" "destinationVmName" number_of_copies  Create multiple clones of virtual machine
        clone "vm1" "vm_cluster" 3                                 It creates 5 clones with name vm_cluster-1, vm_cluster-2, vm_cluster-3
                                                                   After clone script ask for updating vm list in text file
     restart                                                    Restart all cluster, Stopping behavior: acpi power, Starting behavior: headless
     restart destinationVmName                                  Restart specific vm
     command "some command"                                     Run command vms times on host, Patterns to substitute: vmname: #vm , index: #i
        command "VBoxManage startvm "#vm" --type headless"
        command "vboxmanage controlvm #vm natpf1 'OpenSSH,tcp,,200#i,,22'"
     delete                                                     Delete all VMs defined in the mange file
     delete destinationVmName                                   Delete specific virtual machine
     dumplist all                                               Save list of all VMs currently registered on virtualbox into manage file.
     dumplist run                                               Save list of running VMs currently into manage file.
     help                                                       Displays this help

   SPECIAL FLAGS (ENVIRONMENT VARIABLES):
     NO_CONFIRM                If true you will be never asked for confirmation so script run with default states
     DEBUG                     For script debugging purpose
     VERBOSE                   Detailed information for running script
```

## Usage example

Precondition:

- Already prepared VM to copy

1. Copy image and create 4 vm-s Cluster

```bash
./vcm.sh clone "VM_TO_COPY" "CLUSTER" 4
```

Result:

```bash
[INFO] Going to copy VM_TO_COPY.
[INFO] Creating copy VM from VM_TO_COPY to CLUSTER-1
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Machine has been successfully cloned as "CLUSTER-1"
[INFO] Creating copy VM from VM_TO_COPY to CLUSTER-2
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Machine has been successfully cloned as "CLUSTER-2"
[INFO] Creating copy VM from VM_TO_COPY to CLUSTER-3
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Machine has been successfully cloned as "CLUSTER-3"
[INFO] Creating copy VM from VM_TO_COPY to CLUSTER-4
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Machine has been successfully cloned as "CLUSTER-4"
[INFO] Vm VM_TO_COPY cloned to: CLUSTER-1 CLUSTER-2 CLUSTER-3 CLUSTER-4 
Do you want to update mange vm list [vm_list.txt] [y/n] ? y
[INFO] Updating mange file: vm_list.txt
[INFO] VMs cloned
```

Let check how **vm_list.txt** is look like:

```txt
CLUSTER-1
CLUSTER-2
CLUSTER-3
CLUSTER-4
```


2. Run all machines in background

```bash
./vcm.sh start h
```

```bash
[INFO] Going to start all vmstack.
Waiting for VM "CLUSTER-1" to power on...
VM "CLUSTER-1" has been successfully started.
Waiting for VM "CLUSTER-2" to power on...
VM "CLUSTER-2" has been successfully started.
Waiting for VM "CLUSTER-3" to power on...
VM "CLUSTER-3" has been successfully started.
Waiting for VM "CLUSTER-4" to power on...
VM "CLUSTER-4" has been successfully started.
[INFO] VMs stack started.

```

3. Change network adapter to `NAT`

```bash
./vcm.sh command "vboxmanage controlvm #vm nic1 nat"
```

```bash
[INFO] Running command on all cluster VMs.
[INFO] END Running command on all cluster VMs.
```

1. `ACPI Shutdown` with interruption

```bash
./vcm.sh stop a
```

```bash
[INFO] Going to acpipowerbutton action to all vmstack.
[INFO] Going to stop machine with name CLUSTER-1.
[INFO] Going to stop machine with name CLUSTER-2.
[INFO] Going to stop machine with name CLUSTER-3.
[INFO] Going to stop machine with name CLUSTER-4.
[INFO] Machine CLUSTER-1 is running. Waiting to stop
[WARNING] Unable to power off machine CLUSTER-1 
Shall I force poweroff CLUSTER-1 [y/n] ? y    
[INFO] Going to stop machine with name CLUSTER-1.
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Machine CLUSTER-2 is running. Waiting to stop
[WARNING] Unable to power off machine CLUSTER-2 
Shall I force poweroff CLUSTER-2 [y/n] ? y
[INFO] Going to stop machine with name CLUSTER-2.
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Machine CLUSTER-3 is running. Waiting to stop
^C
```

5. `PowerOff` missing not stopped machines

```bash
./vcm.sh stop poweroff
```

```bash
[INFO] Going to poweroff action to all vmstack.
[INFO] Going to stop machine with name CLUSTER-1.
[INFO] Machine CLUSTER-1 already stopped.
[INFO] Going to stop machine with name CLUSTER-2.
[INFO] Machine CLUSTER-2 already stopped.
[INFO] Going to stop machine with name CLUSTER-3.
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Going to stop machine with name CLUSTER-4.
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] VMs stack stopped.
```

6. Delete Cluster

```bash
./vcm.sh delete 
```

```bash
Are you sure you want to remove entire VM cluster (defnined in vm_list.txt) [y/n] ? y
[INFO] Going to remove CLUSTER-1 VM
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Going to remove CLUSTER-2 VM
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Going to remove CLUSTER-3 VM
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] Going to remove CLUSTER-4 VM
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
[INFO] End process of VMs removal.
```

## TBD

- Add all possibilities gathering ip address (DHCP, Guest addon, static)
- Add cluster configuration (Network, Storage, etc.)
- Improve execution over ssh (`./vcm.sh exec`)
- Port to python
- Add support to another virtualization applications
 
## Sources

- [Bash script template](https://github.com/ralish/bash-script-template/blob/main/template.sh)