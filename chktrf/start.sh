#!/bin/sh
./chktrf.pl chktrf.fromphone.conf 1>/dev/null 2>&1 &
./chktrf.pl chktrf.fromapplet.conf 1>/dev/null 2>&1 &
./chktrf.pl chktrf.tomcat.conf 1>/dev/null 2>&1 &
