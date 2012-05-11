#!/bin/sh
for i in $(ps ax | grep "perl ./chktrf.pl" | grep -v grep | awk '{print $1}'); do kill -9 $i; done
