
-- copy the current sessions tracefile from the server

set term feed off 
set pause off verify off

@getpid
@gethostname
@getinstanceowner
@gettrcname

set term on feed on

host mkdir -p trace
host scp &uinstanceowner@&uhostname:&utracefile trace/






