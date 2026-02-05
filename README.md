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

# Building Libvirt
The easy way to build libvirt is to run the VSCode task "Build libvirt" (see [Running Tasks](#Running Tasks)).
This will run the `build-libvirt-rpm-container.bash` script with the appropriate environment variables according to the configured VSCode workspace. 

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