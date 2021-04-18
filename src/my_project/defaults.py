# -*- coding: utf-8 -*-
import os
import sys
from appdirs import AppDirs

my_project_app_dirs = AppDirs("my_project", "frkl")

if not hasattr(sys, "frozen"):
    MY_PROJECT_MODULE_BASE_FOLDER = os.path.dirname(__file__)
    """Marker to indicate the base folder for the `my_project` module."""
else:
    MY_PROJECT_MODULE_BASE_FOLDER = os.path.join(
        sys._MEIPASS, "my_project"  # type: ignore
    )
    """Marker to indicate the base folder for the `my_project` module."""

MY_PROJECT_RESOURCES_FOLDER = os.path.join(MY_PROJECT_MODULE_BASE_FOLDER, "resources")
"""Default resources folder for this package."""
