#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `my_project` package."""

import pytest  # noqa

import my_project


def test_assert():

    assert my_project.get_version() is not None
