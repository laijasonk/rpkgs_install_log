# Install and IV

Bash scripts to install R packages based on R environments described with in yaml files.

## Example 1: Full install

Full installation for a three layers of R packages. For simplicity, every layer is installed in a separate directory; however, different layers may share directories when defined in the \*.config file

```
cd /path/to/parent/directory

# Layer 1
./full_install.sh -y ./examples/layer1.yaml -c ./examples/layer1.config

# Layer 2
./full_install.sh -y ./examples/layer2.yaml -c ./examples/layer2.config

# Layer 3
./full_install.sh -y ./examples/layer3.yaml -c ./examples/layer3.config
```

## Example 2: Build artifactory

Build three layers of R packages (each dependent on the last) into artifactories that can be later installed. The example input builds them into separate directories, but the artifactory directories could have been combined if specified that way in the \*.config file.

```
cd /path/to/parent/directory

# Layer 1
./artifactory_build.sh -y ./examples/layer1.yaml -c ./examples/layer1.config

# Layer 2
./artifactory_build.sh -y ./examples/layer2.yaml -c ./examples/layer2.config

# Layer 3
./artifactory_build.sh -y ./examples/layer3.yaml -c ./examples/layer3.config
```

## Example 3: Install from artifactory

Install three layers of R packages from existing artifactories. This example is dependent on the fact that artifactories has already been prior built. The \*.config file must point to the correct artifactory paths.

```
cd /path/to/parent/directory

# Layer 1
./artifactory_install.sh -y ./examples/layer1.yaml -c ./examples/layer1.config

# Layer 2
./artifactory_install.sh -y ./examples/layer2.yaml -c ./examples/layer2.config

# Layer 3
./artifactory_install.sh -y ./examples/layer3.yaml -c ./examples/layer3.config
```
