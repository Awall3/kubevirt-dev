Scripts and VSCode launch/tasks to run custom qemu/libvirt in kubevirt
# Workspace setup
VSCode supports [mult-root workspaces](https://code.visualstudio.com/docs/editing/workspaces/multi-root-workspaces) for working on multiple source repositories simultaneously. 
The **kubevirt.code-workspace** file in this repo uses this feature to give a unified development environment for kubevirt, libvirt, and qemu (TODO).
The easiest setup is to clone all repos into a single directory tree as shown:
```
project-root/
├── kubevirt
├── libvirt
├── qemu
└── libvirt-dev (this repo)
```
Otherwise, you may edit the **kubevirt.code-workspace** "folders" variable to match you unique directory layout.
It is important to keep the default naming of the directories (kubevirt, libvirt, qemu) regardless of where they are cloned, as the vscode tasks depend on the name of the directories for environment variable references.
Once paths to source directories are correct, you may then open the **kubevirt.code-workspace** workspace file through the `File > Open Workspace from File...` dialog.

Using the VSCode workspace offers a few advantages:
1. Includes some VSCode tasks that can run build scripts with the correct environment automatically
2. Provides the "bash_kubevirt" terminal profile, which adds additional shortcuts to the integrated terminal

## Bash Shortcuts
The following shortcuts are provided and can be run in any workspace integrated terminal
1. **_kubectl**: Shortcut to kubevirt/kubevirtci/cluster-up/kubectl.sh
1. **_cli**: Shortcut to kubevirt/kubevirtci/cluster-up/cli.sh (gocli)
1. **_ssh**: Shortcut to kubevirt/kubevirtci/cluster-up/ssh.sh
1. **_virtctl**: Shortcut to kubevirt/hack/virtctl.sh
1. **clusterup**: Shortcut for `make cluster-up`
1. **clusterdown**: Shortcut for `make cluster-down`
1. **clustersync**: Shortcut for `make cluster-sync`

The shortcuts allow you to easily run the most essential commands for working with a local kubevirt cluster from any working directory. 
This is particularly useful when using the **sandbox** directory of this repository.
My development workflow is to put any yaml VM spec files that I am using to debug and any additional scripts in this directory to maintain a clean kubevirt working tree.
Using the shortcuts you can work entirely out of the **sanbox** working directory to test various libvirt configurations.

# Building Libvirt
The easy way to build libvirt is to run the VSCode task "Build libvirt" (see [Running Tasks](#Running Tasks)).
This will run the `build-libvirt-rpm-container.bash` script with the appropriate environment variables according to the configured VSCode workspace. 

## Confirming build
I opted to add a single debug statement immediately following the QEMU_MONITOR_NEW event to confirm kubevirt was in fact running the built version of libvirt
```c
    // libvirt/src/qemu/qemu_monitor.c function qemuMonitorOpenInternal
    PROBE(QEMU_MONITOR_NEW, "mon=%p fd=%d", mon, mon->fd); 
    VIR_DEBUG("Running custom libvirt");
```

After building libvirt, run `make cluster-up` and `make cluster-sync` (confirm that the **rpms-http-server** container is still running if you encounter 404 errors) to startup the development cluster.
Then, deploy a test VM of any kind, ensuring that the log levels are sufficient to see DEBUG log events (see [libvirt logging](https://kubevirt.io/user-guide/debug_virt_stack/logging/)).
For example, you can use **examples/vm-cirros.yaml** with the following modifications:
```diff
# spec:
#   runStrategy: Halted
#   template:
#     metadata:
+       # Add annotations block **within spec!**
+       annotations:
+         kubevirt.io/libvirt-log-filters: "1:qemu.qemu_monitor 3:*"
#       labels:
#         kubevirt.io/vm: vm-cirros
```

Once the VM has loaded, retreive the logs and grep for the unique message
```bash
kubevirtci/cluster-up/kubectl.sh logs virt-launcher-vm-cirros-XXXXX | grep "Running custom libvirt" 
```

## Detailed build
The `build-libvirt-rpm-container.bash` script creates a persistent docker volume, a libvirt build container, and an httpd rpm repository container according to the documentation found in **kubevirt/docs/custom-repos.md**.
It also updates all necessary files in kubevirt to use the libvirt rpms in a `cluster-up` dev environment.
Details on the script can be found in **docs/building-libvirt.md**.
If you wish to run the script directly from a command line, you will need to define the following environment variables:
```
export LIBVIRT_DIR=<path_to_libvirt_source>
export KUBEVIRT_DIR=<path_to_kubevirt_source>
```

# Running Tasks
The primary ways to run tasks are:

- Command Palette:
    1. Open the Command Palette with Ctrl+Shift+P (Windows/Linux) or Cmd+Shift+P (macOS).
    2. Type Tasks: Run Task and select it from the dropdown menu.
    3. A list of detected or defined tasks will appear; select the one you want to run.
- Keyboard Shortcut:
    - Press Ctrl+Shift+B (Windows/Linux) or Cmd+Shift+B (macOS) to run the default build task.
    - If no default is configured, VS Code will prompt you to select one or configure a default task.
- Quick Open:
    - Open Quick Open with Ctrl+P (Windows/Linux) or Cmd+P (macOS), type task, a space, and then the name of the task you want to run (e.g., task lint). 