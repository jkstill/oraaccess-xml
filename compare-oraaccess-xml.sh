#!/usr/bin/env bash

USERNAME=scott
PASSWORD=tiger
DATABASE='orcl'

# create the table if it does not exist

sqlplus -L -s $USERNAME/$PASSWORD@$DATABASE <<-EOF

-- create some PL/SQL code to create a table if it does not exist

set serveroutput on size unlimited

declare
	table_count integer;
begin
	
	begin
		execute immediate 'select count(*) from user_tables where table_name = ''ARRAYTEST''' into table_count;
	end;

	if table_count = 0 then

		dbms_output.put_line('Creating Table arraytest');

		execute immediate 'create table arraytest (id number, name varchar2(100) )';
	else
		dbms_output.put_line('Table arraytest already exists');
	end if;

end;
/

-- create rows if needed

declare
	rowcount integer;
	create_rows boolean;
begin

	execute immediate 'select count(*) from arraytest' into rowcount;

	if rowcount > 0 then
		create_rows := false;
	else
		create_rows := true;
	end if;

	if create_rows then

		dbms_output.put_line('Creating rows in arraytest');

		insert /*+ append */ into arraytest (id, name) 
		select level, rpad('x', 100, 'x')
		from dual
		connect by level <= 100000;

		commit;

	else
		dbms_output.put_line('Rows already exist in arraytest');
	end if;

end;
/

EOF


for arraysize in NONE 100 500 1000
do

if [[ $arraysize == "NONE" ]]; then
	unset TNS_ADMIN
else
	export TNS_ADMIN=/home/jkstill/oracle/oraaccess-xml/$arraysize
fi

echo "TNS_ADMIN: $TNS_ADMIN"

#continue

# no need to see the output
sqlplus -L -s $USERNAME/$PASSWORD@$DATABASE <<-EOF > /dev/null

	set serveroutput on size unlimited	
	set timing off verify off
	set term off feed off echo off pause off
	set sqlprompt ''
	var identifier varchar2(100);
	exec :identifier := 'ARRAY-' || '$arraysize';
	col identifier new_value identifier

	select :identifier identifier from dual;

	alter session set tracefile_identifier = '&identifier';

	@10046
	select id, name from arraytest;
	@10046_off
	-- comment out the following line if you cannot automatically retrieve the trace file
	@gettracefile
	exit

EOF

done



