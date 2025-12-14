#!/bin/sh

# Release the astute-nas sleep inhibitor early, if present

pkill -f "systemd-inhibit.*--who=astute-nas"

