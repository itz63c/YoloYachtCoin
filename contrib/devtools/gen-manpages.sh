#!/bin/bash

TOPDIR=${TOPDIR:-$(git rev-parse --show-toplevel)}
SRCDIR=${SRCDIR:-$TOPDIR/src}
MANDIR=${MANDIR:-$TOPDIR/doc/man}

YYCCOIND=${YYCCOIND:-$SRCDIR/yyccoind}
YYCCOINCLI=${YYCCOINCLI:-$SRCDIR/yyccoin-cli}
YYCCOINTX=${YYCCOINTX:-$SRCDIR/yyccoin-tx}
YYCCOINQT=${YYCCOINQT:-$SRCDIR/qt/yyccoin-qt}

[ ! -x $YYCCOIND ] && echo "$YYCCOIND not found or not executable." && exit 1

# The autodetected version git tag can screw up manpage output a little bit
YYCVER=($($YYCCOINCLI --version | head -n1 | awk -F'[ -]' '{ print $6, $7 }'))

# Create a footer file with copyright content.
# This gets autodetected fine for bitcoind if --version-string is not set,
# but has different outcomes for bitcoin-qt and bitcoin-cli.
echo "[COPYRIGHT]" > footer.h2m
$YYCCOIND --version | sed -n '1!p' >> footer.h2m

for cmd in $YYCCOIND $YYCCOINCLI $YYCCOINTX $YYCCOINQT; do
  cmdname="${cmd##*/}"
  help2man -N --version-string=${YYCVER[0]} --include=footer.h2m -o ${MANDIR}/${cmdname}.1 ${cmd}
  sed -i "s/\\\-${YYCVER[1]}//g" ${MANDIR}/${cmdname}.1
done

rm -f footer.h2m