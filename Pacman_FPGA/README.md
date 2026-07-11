# Instructions for Environment Set Up and Using Project Template

Please use the structure of this repository as a template for your project's directory structure. A Makefile has been included; it can be used to simulate the source and synthesized versions of any of the designs you include within the directory structure. Below are the steps to set up your project and a quick overview of the Makefile targets.

## Step 1: Create repository from template
On the top right of the template repository page, click on **Use this template** and then on **Create a new repository**. Give your repository a descriptive name and make it *Private*. Verify that the owner of the repository is Purdue-SoCET. Once you have created the repository, log in to your asicfab account and clone it.

## Step 2: Add to your `.bashrc`

As part of the toolchain, you'll be using Yosys, a framework for Verilog RTL synthesis. Log in to your asicfab account, add `module load yosys` to your `~/.bashrc` be enable Yosys commands. You only need to do this once. Log out and log back in your account or run `source ~/.bashrc` for the changes to take place. 

## Step 3: Install PDK

We'll be using the open-source sky130A PDK. Run `make setup_pdk` to install and load all PDK files. After the command is done running, you should see a `pdks` folder within your project directory. Unless you delete this directory, you only have to run this setup command once.

## Step 4: Compiling, Synthesizing, and Simulating

Include all source code (.sv and .v files) of your design inside the `source` folder. Include all testbench code (.sv and .v files) of your design inside the `testbench` folder. Each module in your top level design should be in its own `<module-name>.sv` file where `<module-name>` is the name of the module contained in the file. Similarly, the testbench for each module should be in its own `<module_name>_tb.sv` file. Take a look at the example design provided. File `example_counter.sv` contains module example_counter, and file `example_counter_tb.sv` contains the testbench for example_counter.

To compile and simulate the source version of module example_counter, run `make sim_example_counter_src`. The testbench will run, and you'll see any output on your terminal. In general, you can compile and simulate the source version of a design with name `%` by running `make sim_%_src`.

To synthesize the example_counter design, run `make syn_example_counter`. A folder called `mapped` is created and the Verilog code of the synthesized design (example_counter.v) is placed there. You can synthesize any design of name `%` by running `make syn_%`.

Run `sim_example_counter_syn` to compile and simulate the synthesized design. The testbench will simulate the synthesized version instead of the source version this time. You can run `make sim_%_syn` to compile the synthesized design of name `%`.

## Step 5: Viewing Waves and Debugging
Once you've simulated your design, either source or synthesized, you can open the waveforms for viewing or debugging by using the `waves_%` target. So, if the design is example_counter, you would run `make waves_example_counter`. An error will appear if the design hasn't been compiled and simulated yet.

## Additional notes
- Use `make clean` to remove any temporary files from synthesis, compilation, and simulation.
- Use `make veryclean` to remove all temporary files AND PDK files.
- Run `make help` for more information on all the Makefile targets.
- Add documentation for your project under `/docs`. Check out `docs/info.md` for more instructions.

## Flashing on the FPGA
Details about which FPGA to use are still being figured out. Once the decision has been made, targets to flash your design on the FPGA will be included.

## [Optional]: Setting Up Connection to Visual Studio Code
[Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) has excellent instructions for setting up an SSH key. You'll get a `private` and `public` key, differentiated by the suffix `.pub` on the `public` key. You can use your private key with the following commands:

```
eval `ssh-agent`                        # start the ssh agent
ssh-add ~/.ssh/{your private key file}  # add your ssh key to the agent
```

It's probably smart to add these to your `~/.bashrc` file so that they run every time you open your terminal.

Once you've got a key, you'll want to set up a config entry for Visual Studio Code. If you don't have it, download the `Remote Explorer` extension on VSCode. Open it up, then click `Open SSH Config File`. SSH config entries generally look like this:

```
Host {name of the entry}
    HostName {the address of the ssh server}
    User {username on the ssh server}
    IdentityFile {filepath of your private key}
```

Make entries for both `ececomp` and `asicfab`. For me (Miguel), they look like this:

```
Host ececomp
    HostName ececomp.ecn.purdue.edu
    User misrrael                          # here you use your Purdue username
    IdentityFile ~/.ssh/id_rsa

Host asicfab
    HostName asicfab.ecn.purdue.edu
    User misrrael                       # here you use your SoCET username
    IdentityFile ~/.ssh/id_rsa
    ProxyJump ececomp                   # you can't directly ssh into asicfab, 
                                        # so we use ececomp as a proxy 
```

These endpoints will show up in the vscode remote explorer or you can use them through the terminal like:

```
ssh ececomp
ssh asicfab
```

To get them to work, you'll need to copy the contents of your public key file into the `~/.ssh/authorized_keys` file on ececomp and asicfab. Without the SSH key, you can connect to these servers using your password. You may need to create the `.ssh` directory and `authorized_keys` file.

Once you've copied your `public` key onto a server you should be able to SSH in without using a password.
