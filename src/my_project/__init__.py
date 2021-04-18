# -*- coding: utf-8 -*-
"""Top-level package for '*my-project*'."""

__all__ = ["__author__", "__email__", "get_version"]

import logging
import os

log = logging.getLogger("my_project")

__author__ = """Markus Binsteiner"""
"""The (main) author of '*my-project*'."""
__email__ = "markus@frkl.io"
"""The email address of the (main) author of '*my-project*'."""


def get_version() -> str:
    """Return the current version of '*my-project*'.

    Returns:
        the version string, or 'unknown'
    """

    from pkg_resources import DistributionNotFound, get_distribution

    try:
        # Change here if project is renamed and does not equal the package name
        dist_name = __name__
        __version__ = get_distribution(dist_name).version
    except DistributionNotFound:

        try:
            version_file = os.path.join(os.path.dirname(__file__), "version.txt")

            if os.path.exists(version_file):
                with open(version_file, encoding="utf-8") as vf:
                    __version__ = vf.read()
            else:
                __version__ = "unknown"

        except (Exception):
            pass

        if __version__ is None:
            __version__ = "unknown"

    return __version__
