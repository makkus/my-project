# Installation

There are three ways to install *my-project* on your machine. Via a manual binary download, an install script, or installation of the python package.

## Binaries

To install the `my-project` binary, download the appropriate binary from one of the links below, and set the downloaded file to be executable (``chmod +x my-project``):

  - [Linux](https://s3-eu-west-1.amazonaws.com/dev.dl.frkl.io/linux-gnu/my-project)
  - [Windows](https://s3-eu-west-1.amazonaws.com/dev.dl.frkl.io/windows/my-project.exe)
  - [Mac OS X](https://s3-eu-west-1.amazonaws.com/dev.dl.frkl.io/darwin/my-project)


## Install script

Alternatively, use the 'curly' install script for `my-project`:

``` console
curl https://gitlab.com/frkl/my-project/-/raw/develop/scripts/install/my-project.sh | bash
```


This will add a section to your shell init file to add the install location (``$HOME/.local/share/frkl/bin``) to your ``$PATH``.

You might need to source that file (or log out and re-log in to your session) in order to be able to use *my-project*:

``` console
source ~/.profile
```


## Python package

The python package is currently not available on [pypi](https://pypi.org), so you need to specify the ``--extra-url`` parameter for your pip command. If you chooose this install method, I assume you know how to install Python packages manually, which is why I only show you an example way of getting *my-project* onto your machine:

``` console
> python3 -m venv ~/.venvs/my-project
> source ~/.venvs/my-project/bin/activate
> pip install --extra-index-url https://gitlab.com/api/v4/projects/25344049/packages/pypi/simple my-project
...
...
Successfully installed aiokafka-0.6.0 aiopg-1.0.0 ... ... ...
> my-project --help
Usage: my-project [OPTIONS] COMMAND [ARGS]...
   ...
   ...
```
