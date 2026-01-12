#!/usr/bin/env bash

Describe "check-zfs.sh"
  It "warns when the pool is not imported"
    When run env ZPOOL_LIST_FAIL=1 \
      script "$ROOT/bin-astute/.local/bin/check-zfs.sh"
    The status should be success
    The output should include "ZFS pool 'ironwolf' is not imported."
  End

  It "warns when datasets are not mounted"
    When run env ZFS_MOUNTED=no \
      script "$ROOT/bin-astute/.local/bin/check-zfs.sh"
    The status should be success
    The output should include "ZFS datasets for 'ironwolf' are not mounted."
  End
End
