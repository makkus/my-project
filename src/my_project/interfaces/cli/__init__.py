# -*- coding: utf-8 -*-
"""The entry point for the commandline-interface for *my-project*."""

import asyncclick as click

try:
    import uvloop

    uvloop.install()
except Exception:
    pass

click.anyio_backend = "asyncio"


@click.command()
@click.pass_context
def cli(ctx):

    print("Hello World!")


if __name__ == "__main__":
    cli()
