#!/bin/sh

qq ()
{
	loc=$(readlink -f $(which q))
	local QHOME=${loc%/l64/q}
	QHOME=$QHOME rlwrap -c -s 99999 $loc $@ -c $LINES $COLUMNS
}

function qspec() {
    qq $QPATH/src/qspec/app/spec.q $@
}

function printlastarg
{
	awk '{print $NF}' $@
}
