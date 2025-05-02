Controlling Oracle Fetch Sizes with oraaccess.xml
=================================================

Most Oracle DBAs are probably familiar with the concept of fetch size. The fetch size
is the number of rows that are fetched from the database in a single round trip. 

This can have a significant impact on performance, especially when dealing with large result sets.

In sqlplus, the default fetch size is 15 rows. This can be changed using the `set array size` command.

In Perl, the fetch size can be controlled by setting the database handle attribute `RowCacheSize`: `$dbh->{RowCacheSize} = 100`

In JDBC, the default fetch size is 10 rows. This can be changed using the `setFetchSize` method on the `Statement` or `PreparedStatement` object.

In Python the fetch  can be changed using the `fetch_size` attribute of the PreparedStatement object, or at a session level with the `default_fetch_size` attribute of the connection object.

This is all good to know.  However, this does not really help the DBA or Performance Analyst that would like to improve the network performace of an application.

We don't usually have access to the source code, and even if we did, we would probably not be allowed to change it.

Oracle has a file that allows an easy way to change the fetch size of any applications that use Oracle libraries for connections.

This file is called oraaccess.xml and is by default located in the `$ORACLE_HOME/network/admin` directory.

This method works with applications using any of the following:

- Perl DBD::Oracle
- Python cx_Oracle
- Java Thick Client
- Any application that is compiled with Oracle libraries.
  - C, C++
  - Fortran
  - COBOL

This method will not work for applications that do not use Oracle libraries for connections.

The Java Thin Client is a good example of this.  
The Java Thin Client does not use the Oracle libraries for connections, and therefore does not use the oraaccess.xml file.

There are other methods that may be used to control the fetch size of applications that do not use Oracle libraries for connections, 
but we will not cover them here.

A well known Oracle application that can make use of oraaccess.xml is Sql*Plus.

## What is oraaccess.xml?

The oraaccess.xml file is an XML file that contains configuration settings for Oracle client applications. 

It allows you to specify various parameters, including the fetch size, for all Oracle client applications that use the Oracle libraries.

For our purposes, the oraaccess.xml file will be used only to set the default fetch size for tests with sqlplus.

### How to set the fetch size in oraaccess.xml

It is fairly straightforward to set the fetch size in oraaccess.xml as per the following example:

````xml
<?xml version="1.0" encoding="ASCII" ?> 
 <oraaccess xmlns="http://xmlns.oracle.com/oci/oraaccess"
  xmlns:oci="http://xmlns.oracle.com/oci/oraaccess"
  schemaLocation="http://xmlns.oracle.com/oci/oraaccess
  http://xmlns.oracle.com/oci/oraaccess.xsd">
  <default_parameters>
    <prefetch>
      <rows>100</rows> 
    </prefetch>
  </default_parameters>
</oraaccess>
```

The 'prefetch' element is used to set the fetch size. The 'rows' element specifies the number of rows to fetch in a single round trip.

That's all there is to it.

## Testing with SQL*Plus and mrskew

You are likely familiar with sqlplus, as it is a standard oracle tool.

Method R mrskew is a tool that can be used to test the performance of sqlplus with different fetch sizes.

The entire suite of Method R tools are my goto choice for analyzing Oracle SQL Trace files. 

They can be found at [Method R Workbench](https://carymillsap.com/software/workbench/)

BTW, these tools are free, and are available for Windows, Linux, and MacOS.

All code used in this article is available at [oraaccess-xml](https://github.com/jkstill/oraaccess-xml), and so will not be included in the article.

Any `rc` files used with mrskew are available here: [jkstill mrtools rc files](https://github.com/jkstill/mrtools)

### How to test

The default location for  `*.ora` oracle configuration files is `$ORACLE_HOME/network/admin`.
This is also where `oraaccess.xml` is located.

This location can be changed by setting the `TNS_ADMIN` environment variable to point to a different directory.

Here is how the testing will proceed:

- create and popoulate a test table
  - the script will create a table with 100k rows, only if it does not already exist
  - sqlplus will be run with sqltrace enabled
  - the trace file will be fetched and analyzed with mrskew

- Use TNS_ADMIN to point to the directory where oraaccess.xml is located
  - NONE: default location. In this case there is no oraaccess.xml file at OH/network/admin
  - 100/oraaccess.xml: 100 row fetch size
  - 500/oraaccess.xml: 500 row fetch size
  - 1000/oraaccess.xml: 1000 row fetch size


Here is a sample run of the script:

```text
$  ./compare-oraaccess-xml.sh
Creating Table arraytest

PL/SQL procedure successfully completed.

Creating rows in arraytest

PL/SQL procedure successfully completed.

TNS_ADMIN:
TNS_ADMIN: /home/jkstill/oracle/oraaccess-xml/100
TNS_ADMIN: /home/jkstill/oracle/oraaccess-xml/500
TNS_ADMIN: /home/jkstill/oracle/oraaccess-xml/1000
$
```

Here are the contents of the `trace/` directory:

```text
$  ls -latr trace/*.trc
-rw-r----- 1 jkstill jkstill 2358427 May  1 11:11 trace/orcl1901_ora_1358976_ARRAY-NONE.trc
-rw-r----- 1 jkstill jkstill  343126 May  1 11:11 trace/orcl1901_ora_1359072_ARRAY-100.trc
-rw-r----- 1 jkstill jkstill   74920 May  1 11:11 trace/orcl1901_ora_1359116_ARRAY-500.trc
-rw-r----- 1 jkstill jkstill   53364 May  1 11:11 trace/orcl1901_ora_1359158_ARRAY-1000.trc
```

Just comparing the sizes of the trace files gives us a good idea of the performance of the different fetch sizes.

## Analyze the trace files with mrskew

The rc file `fetch-snmfc.rc` is used to analyze the trace files. This rc file will restrict the output to FETCH, EXEC calls that had the FETCH included, and SQL*Net messages to and from the client.

In each case the FETCH and EXEC calls are grouped by name and the number of rows returned per call.

The SQL*Net messages are grouped by name only.


### Default Fetch Size

The baseline is to not use any oraaccess.xml file. This is the default fetch size of 15 rows for sqlplus.

We see that 6,666 FETCH calls were made that each returned 15 rows. 

The total number of rows returned was 100,000.

Of particular interest is the time spent waiting on the network.

This is not because the network was slow (average wait time was 0.000397 seconds), but because the application made far too many calls to the database.


```text
$  mrskew --rc fetch-snmfc.rc trace/orcl1901_ora_1358976_ARRAY-NONE.trc
                          CALL:NNNNNNNNN  DURATION       %   CALLS      MEAN       MIN       MAX
----------------------------------------  --------  ------  ------  --------  --------  --------
   SQL*Net message from client:           2.646101   99.9%   6,671  0.000397  0.000187  0.001386
                         FETCH:000000015  0.001155    0.0%   6,666  0.000000  0.000000  0.000016
     SQL*Net message to client:           0.000361    0.0%   6,671  0.000000  0.000000  0.000002
                         FETCH:000000001  0.000018    0.0%       1  0.000018  0.000018  0.000018
                          EXEC:000000000  0.000010    0.0%       1  0.000010  0.000010  0.000010
                         FETCH:000000009  0.000000    0.0%       1  0.000000  0.000000  0.000000
----------------------------------------  --------  ------  ------  --------  --------  --------
TOTAL (6)                                 2.647645  100.0%  20,011  0.000132  0.000000  0.001386
```

### 100 Row Fetch Size

With 100 rows, the total amount of time spent waiting on the network is reduced from 2.646 seconds to 1.671 seconds.

```text
$ mrskew --rc fetch-snmfc.rc trace/orcl1901_ora_1359072_ARRAY-100.trc
                          CALL:NNNNNNNNN  DURATION       %  CALLS      MEAN       MIN       MAX
----------------------------------------  --------  ------  -----  --------  --------  --------
   SQL*Net message from client:           1.662761   99.5%    956  0.001739  0.000231  0.002668
                         FETCH:000000105  0.008220    0.5%    951  0.000009  0.000000  0.000035
     SQL*Net message to client:           0.000051    0.0%    956  0.000000  0.000000  0.000001
                         FETCH:000000100  0.000023    0.0%      1  0.000023  0.000023  0.000023
                          EXEC:000000000  0.000009    0.0%      1  0.000009  0.000009  0.000009
                         FETCH:000000045  0.000007    0.0%      1  0.000007  0.000007  0.000007
----------------------------------------  --------  ------  -----  --------  --------  --------
TOTAL (6)                                 1.671071  100.0%  2,866  0.000583  0.000000  0.002668
```

### 500 Row Fetch Size

With a fetch size of 500 rows, the total amount of time spent waiting on the network is reduced from 1.671 seconds to 1.530 seconds.

This is not nearly as large a gain as was seen when comparing the default fetch size of 15 rows to 100 rows.

When large amounts of data must be moved however, the difference could still be significant.

```text
$ mrskew --rc fetch-snmfc.rc trace/orcl1901_ora_1359116_ARRAY-500.trc
                          CALL:NNNNNNNNN  DURATION       %  CALLS      MEAN       MIN       MAX
----------------------------------------  --------  ------  -----  --------  --------  --------
   SQL*Net message from client:           1.524779   99.6%    200  0.007624  0.000221  0.008691
                         FETCH:000000510  0.006030    0.4%    195  0.000031  0.000000  0.000054
                         FETCH:000000500  0.000045    0.0%      1  0.000045  0.000045  0.000045
     SQL*Net message to client:           0.000035    0.0%    200  0.000000  0.000000  0.000001
                         FETCH:000000050  0.000011    0.0%      1  0.000011  0.000011  0.000011
                          EXEC:000000000  0.000010    0.0%      1  0.000010  0.000010  0.000010
----------------------------------------  --------  ------  -----  --------  --------  --------
TOTAL (6)                                 1.530910  100.0%    598  0.002560  0.000000  0.008691
```

### 1000 Row Fetch Size

The final test was to set the fetch size to 1000 rows.

Again, the time spent waiting on the network is reduced from 1.530 seconds to 1.492 seconds.

A difference of 0.038 seconds may not be important most of the time.

This test is for a relatively small amount of data (100k rows).

If this test were for 500 million rows, the difference would be 190 seconds.

This may be important for large volumes of data.

```text
$ mrskew --rc fetch-snmfc.rc trace/orcl1901_ora_1359158_ARRAY-1000.trc
                          CALL:NNNNNNNNN  DURATION       %  CALLS      MEAN       MIN       MAX
----------------------------------------  --------  ------  -----  --------  --------  --------
   SQL*Net message from client:           1.485908   99.6%    103  0.014426  0.000205  0.015652
                         FETCH:000001005  0.006022    0.4%     98  0.000061  0.000000  0.000138
                         FETCH:000001000  0.000083    0.0%      1  0.000083  0.000083  0.000083
                         FETCH:000000510  0.000035    0.0%      1  0.000035  0.000035  0.000035
     SQL*Net message to client:           0.000017    0.0%    103  0.000000  0.000000  0.000002
                          EXEC:000000000  0.000011    0.0%      1  0.000011  0.000011  0.000011
----------------------------------------  --------  ------  -----  --------  --------  --------
TOTAL (6)                                 1.492076  100.0%    307  0.004860  0.000000  0.015652
```

## Conclusion

The oraaccess.xml file is a powerful tool that can be used to control the fetch size of Oracle client applications.

It is simple to use and can have a significant impact on performance, especially when dealing with large result sets.


