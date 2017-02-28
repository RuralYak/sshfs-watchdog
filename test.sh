#!/bin/bash

ping -f -i 1 172.16.254.105 2>/dev/null | {
  function ord {
    printf -v "${1?Missing Dest Variable}" "${3:-%d}" "'${2?Missing Char}"
  }

  function ord_hex {
    ord "${@:1:2}" "0x%x"
  }

  register=

  while IFS= read -r -n1 c
  do
    #echo "${c}" >> /tmp/output.log
    ord_hex code "$c"

    echo "$code"

    if [ -z "$register" ]; then
      register="$code"
    else
      register="$code"
      case "$code" in
        "0x8" ) # BACKSPACE
          echo "OK"
          register=
        ;;
        "0x2e" ) # dot
          echo "NOACK"
        ;;
        "0x45" ) # E
          echo "ERR"
        ;;
        * )
          echo "$code"
        ;;
      esac
    fi
  done
}
