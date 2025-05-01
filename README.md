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

The mrskew tool is a tool that can be used to test the performance of sqlplus with different fetch sizes.

(Here I need to introduce mrskew, but Method R is ceasing operations, and the softwar is moving.  I have asked how I should now refer to it)

All code used here is available at [oraaccess-xml](https://github.com/jkstill/oraaccess-xml), and so will not be included in the article.

Any `rc` files used with mrskew are available here: [jkstill mrtools rc files](https://github.com/jkstill/mrtools)

### How to test

The default location for  `*.ora` oracle configuration files is `$ORACLE_HOME/network/admin`.
This is also where `oraaccess.xml` is located.

This location can be changed by setting the `TNS_ADMIN` environment variable to point to a different directory.

That is how this testing will work. 















