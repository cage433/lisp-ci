#!/bin/bash

while [ true ]; do
  # Weirdly, unless the command is wrapped in a $() we can't Ctrl-C the script
  find . -name '*.lisp' | xargs fswatch -1 > /dev/null 2>&1
  tmux set -q -g status-bg black
  rlwrap sbcl --noinform --load load --eval '(ci)'
  if [[ $? == 0 ]]; then
    tmux set -q -g status-bg blue
  else
    tmux set -q -g status-bg red
  fi
done


