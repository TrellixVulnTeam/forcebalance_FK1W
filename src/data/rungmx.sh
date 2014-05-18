#!/bin/bash

# This wrapper script is for running GROMACS jobs on clusters.

# Command line switch indicates whether to do backups
do_bak=0
while [ $# -gt 0 ]
do
    case $1 in
        -b) do_bak=1 ;;
        *) break ;;
    esac
    shift
done

# This is the command that we want to run.
COMMAND=$@

# Load my environment variables. :)
. /etc/profile
. /etc/bashrc
. ~/.bashrc

# Load Gromacs environment variables if needed (e.g. Intel compiler variables)
if [[ $HOSTNAME =~ "biox3" ]] ; then
    # biox3 cluster
    . ~/opt/intel/bin/compilervars.sh intel64
fi

# Backup folder
export BAK=$HOME/temp/rungmx-backups

# Disable GROMACS backup files
export GMX_MAXBACKUP=-1

echo "#=======================#"
echo "# ENVIRONMENT VARIABLES #"
echo "#=======================#"
echo

env

echo
echo "#=======================#"
echo "# STARTING CALCULATION! #"
echo "#=======================#"
echo
echo $COMMAND

rm -f npt_result.p npt_result.p.bz2
export PYTHONUNBUFFERED="y"

# Unset OMP_NUM_THREADS otherwise gromacs will complain.
unset OMP_NUM_THREADS
unset MKL_NUM_THREADS

# Actually run the command.
time $COMMAND
exitstat=$?

# Delete backup files that are older than one week.
find $BAK -type f -mtime +7 -exec rm {} \;

# Copy backup files.
if [ $do_bak -gt 0 ] ; then
    mkdir -p $BAK/$PWD
    cp * $BAK/$PWD
fi

# For some reason I was still getting error messages about the bzip already existing..
rm -f npt_result.p.bz2
if [ -f npt_result.p ] ; then bzip2 npt_result.p ; fi

exit $exitstat
