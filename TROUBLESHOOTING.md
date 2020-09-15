# Troubleshooting for Palette Insight

## Access the Tableu Repository from the Palette Server

```bash
psql -h <ADDRESS_OF_THE_TABLEAU_REPOSITORY> -d workgroup -U readonly -p 8060
```

## Access the Palette Database locally on the Palette Server

You can access the Greenplum database via this shell command:

```bash
psql -h 127.0.0.1 -d palette -U readonly
```

or

```bash
psql -h 127.0.0.1 -d palette -U palette
```

## Get information from the database

### Check installed datamodel version

```sql
select *
from
    palette.db_version_meta
order by 1 desc
limit 1
;
```

### Get all the tables of the DB

```sql
select * from information_schema.tables
where table_schema = 'palette' and table_type='BASE TABLE';
```

or

```sql
select * from pg_tables where schemaname='palette';
```

### Check the size of the databases

```sql
SELECT pg_database.datname,
       pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database;
```

### Check the size of the tables

```sql
SELECT relname                                                                 as "Table",
       pg_size_pretty(pg_total_relation_size(relid))                           As "Size",
       pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as "External Size"
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

Check the size and the entries of the tables

```sql
SELECT relname                                     AS objectname,
       relkind                                     AS objecttype,
       reltuples                                   AS "#entries",
       pg_size_pretty(relpages::bigint * 8 * 1024) AS size
FROM pg_class
WHERE relpages >= 8
ORDER BY relpages DESC;
```

### Check running processes

```sql
select * from pg_stat_activity;
```

### Check whether DEBUG logs are enabled

The following SQL should return `debug` rows too.

```sql
select sev, count(1) from palette.p_serverlogs_bootstrap_rpt group by sev;
```

## Upgrade

### Install new Datamodel

The following steps are to be executed before a new version of the Datamodel is installed

1. Prevent new execution of reporting by commenting out the scripts in the crontab of the insight user

1. Wait for the finish of the current reporting or terminate the process with:

   ```sql
   SELECT * FROM pg_stat_activity WHERE state = 'active';
   SELECT pg_terminate_backend(<pid of the process>);
   ```

1. Check the reporting.log for terminated or finished job.

   ```bash
   less /var/log/insight-reporting-framework/reporting.log
   ```

1. Install the new version

   ```bash
   sudo yum install -y palette-insight-reporting-framework-v2.4.0.11-11.x86_64.rpm
   ```

1. Uncomment the scripts in the crontab of the insight user (change minute part to start reporting the next minute)

## Wipe Insight Server

The following process can be used to wipe all data from the Palette Insight Server.

1. Save the metadata file

    ```bash
    cd /data
    find palette-insight-server/ -name metadata\* -print0 | tar -cvf metadata.tar --null -T -
    ```

1. Stop insight server

   ```bash
   sudo supervisorctl stop palette-insight-server
   ```

1. Stop crontab jobs

   Comment the lines in the crontab of the insight user.

   ```bash
   sudo crontab -u insight -e
   ```

1. Terminate DB sessions

  ```bash
  sudo su postgres -g postgres -c "psql"
  ```
  
   ```sql
  SELECT pg_terminate_backend(pid),pid,datname,usename,state,query FROM pg_stat_activity;
   ```
  
1. Drop DB

   ```sql
   DROP DATABASE palette;
   ```

1. Drop palette roles

   ```sql
   DROP ROLE palette_palette_looker;
   DROP ROLE palette_palette_updater;
   DROP ROLE readonly;
   DROP ROLE readonly_live;
   DROP ROLE palette;
   DROP ROLE palette_etl_user;
   DROP ROLE palette_extract_user;
   ```
   
1. Create DB

   ```sql
   CREATE DATABASE palette;
   ```

1. 1. Delete files from /data

   ```bash
   rm -rf /data/palette-insight-server
   ```

1. Start crontab jobs

   Uncomment the lines in the crontab of the insight user.

   ```bash
   sudo crontab -u insight -e
   ```

1. Start insight server

   ```bash
   sudo supervisorctl start palette-insight-server
   ```
   
1. Postchecks

   ```bash
   sudo supervisorctl status
   sudo crontab -u insight -l
   tail -f /var/log/palette-insight-server/loadtables.log
   ```

## Missing data from Agents

### Incorrect access token

Please make sure that the value of the key `InsightAuthToken` in the `Config\Config.yml` files on the agents and the `license_key` key of the `/etc/palette-insight-server/server.config` on the server are matching.

### Incorrect server endpoint url

Please make sure that there is no trailing `/` character in the `Endpoint` in the `Config\Config.yml` files on the agents.

Incorrect:

```yaml
Webservice:
  Endpoint: https://server/
```

Correct:

```yaml
Webservice:
  Endpoint: https://server
```

## Greenplum Out of memory

https://greenplum.org/calc/

## Performance dashboard missing data

### Check the last loaded day

```sql
select max(load_date)
from palette.p_load_dates;
```

### Check incrementally loaded tables (maxids)

See [example for `http_requests` table](#compare-maxids-in-tableau-and-insight-server).

### Check the last sessions that should show up in the Performance dashboard

The table `p_interactor_session_normal` is feeding the Performance dashboard.
```sql
select * from palette.p_interactor_session_normal order by session_start_ts desc limit 10;
```

```sql
select session_start_ts::date, count(1)
from palette.p_interactor_session_normal
group by session_start_ts::date
order by session_start_ts::date;
```

```sql
select session_start_ts::date, count(1)
from palette.p_interactor_sessions
group by session_start_ts::date
order by session_start_ts::date;
```

### Datasource extracts are failing because of timeout (7200 seconds)

#### Check information about the extracts

```sql
select
    title
    ,started_at
    ,completed_at
    ,completed_at - started_at as duration
from
        palette.background_jobs
where 1 = 1
    and progress = 100
    and job_name in ('Increment Extracts', 'Refresh Extracts')
order by created_at desc
limit 1000;
```

#### Check number of records in the tables

```sql
select count(1) from palette.p_cpu_usage_bootstrap_rpt;
select count(1) from palette.p_serverlogs_bootstrap_rpt;
select count(1) from palette.p_interactor_session;
```

#### Check the number of records by day

```sql
select ts_rounded_15_secs::date as day, host_name, count(1) from palette.p_process_class_agg_report
  where ts_rounded_15_secs > '2020-01-01'::date
group by 1, 2
order by 1 desc;
```

or

```sql
select start_ts::date, count(1) from palette.p_serverlogs_bootstrap_rpt group by start_ts::date order by start_ts::date;
```

or

```sql
select
     created_at::date as created_at
    ,count(1) as cnt
    ,min(id) as min_id
    ,max(id) as max_id
from
    palette.http_requests
group by
    created_at::date
order by 1;
```

or

```sql
select
    ts::date, count(1)
from
    palette.backgrounder_logs
group by
    ts::date
order by
    ts::date;
```

or

```sql
select ts_rounded_15_secs::date as day, host_name, count(1) from palette.p_process_class_agg_report
group by 1, 2
order by 1 desc;
```



#### Check partitions of a table

```sql
SELECT i.inhrelid::regclass AS child
FROM   pg_inherits i
WHERE  i.inhparent = 'palette.p_interactor_session'::regclass;	
```

or

```sql
select * from pg_partitions
where schemaname='palette' and tablename='p_interactor_session' and partitiontype='range';
```

#### Drop archive data

```sql
alter table palette.p_interactor_session drop partition "2018";
```

#### Deduplicate data

Create new table without duplicates:

```sql
create table palette.http_requests_dedup_20190530 as
select *
from
    (select
         *
        ,row_number() over (partition by id order by p_cre_date) as rn
    from
        palette.http_requests
    ) a
where rn = 1;
```

Drop table with duplicates:

```sql
DROP TABLE palette.http_requests;
```

Rename table without duplicates:

```sql
ALTER TABLE palette.http_requests_dedup_20190530 RENAME TO palette.http_requests;
```

#### Remove huge amout of data both from agent and server

##### On the Tableau Server nodes

1. Stop the Insight Agent Services (agent and watchdog)
1. Delete the **data** folder in installation directory of  the Palette Insight Agent

##### On the server

1. Turn off the cronjobs for the insight user:

   ```bash
   sudo su insight
   crontab -e
   # Add the "#" signs to the beginning of the 3 schedules
   ```

1. Delete the uploads folder:

   ``````bash
   rm -rf /data/palette-insight-server/uploads/
   ``````

1. Truncate tables in database:

   ```sql
   truncate table palette.tmp_http_requests;
   truncate table palette.http_requests_20190401;
   truncate table palette.pool_http_requests;
   ```

1. Turn on the cronjobs for the insight user:

   ```bash
sudo su insight
   crontab -e
   # Remove the "#" signs from the beginning of the 3 schedules
   ```
## Repository polling

The repository is not polled if the log has lines like:

   ```text
Target Tableau repo is not located on this computer. Skip polling full tables.
   ```

```text
Target Tableau repo is not located on this computer. Skip polling streaming tables.
```

### Check time of last received data from Tableau repository

```sql
select
     created_at::date
    ,count(1) as cnt
from
    palette.http_requests
group by
    created_at::date
order by 1 desc
;
```

### Insight has fallen too much behind in processing one or more Tableau repo tables
#### Issue

If you have a feeling or proof that any of the Tableau repo tables is not being fetched properly, then you can take the following measurement.

#### Compare maxids in Tableau and Insight Server

##### To check the last id of the synchronized record of `http_requests` at Insight Server

```bash
cat /data/insight-server/maxids/palette/http_requests
```

##### To check the most recent record id in Tableau

First you need to connect to the `workgroup` database of the Tableau Server and then execute:

```sql
select max(id) from http_requests;
```

#### Error in agent logs

In our example, let's assume that we realize that `http_requests` table is not being populated at all since last week. And also let's say that we find log lines like this from the Insight Agents which are running on the repository nodes of Tableau.

```
2019/01/23 14:26:05.856 [19]  ERROR    PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn - NPGSQL exception while retreiving data from Tableau repository Query: select * from http_requests where id > '184439774
' and id <= '199157406' Exception: Npgsql.NpgsqlException (0x80004005): 57014: canceling statement due to statement timeout
   at Npgsql.NpgsqlConnector.DoReadSingleMessage(DataRowLoadingMode dataRowLoadingMode, Boolean returnNullForAsyncMessage, Boolean isPrependedMessage)
   at Npgsql.NpgsqlConnector.ReadSingleMessage(DataRowLoadingMode dataRowLoadingMode, Boolean returnNullForAsyncMessage)
   at Npgsql.NpgsqlDataReader.ReadMessage()
   at Npgsql.NpgsqlDataReader.ReadInternal()
   at Npgsql.NpgsqlDataReader.Read()
   at System.Data.Common.DataAdapter.FillLoadDataRow(SchemaMapping mapping)
   at System.Data.Common.DataAdapter.FillFromReader(DataSet dataset, DataTable datatable, String srcTable, DataReaderContainer dataReader, Int32 startRecord, Int32 maxRecords, DataColumn parentChapterColumn, Object parentChapterValue)
   at System.Data.Common.DataAdapter.Fill(DataTable[] dataTables, IDataReader dataReader, Int32 startRecord, Int32 maxRecords)
   at System.Data.Common.DbDataAdapter.FillInternal(DataSet dataset, DataTable[] datatables, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior)
   at System.Data.Common.DbDataAdapter.Fill(DataTable[] dataTables, Int32 startRecord, Int32 maxRecords, IDbCommand command, CommandBehavior behavior)
   at System.Data.Common.DbDataAdapter.Fill(DataTable dataTable)
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.<>c__DisplayClass11_0.<runQuery>b__0()
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.queryWithReconnect(Func`1 query, Object def, String sqlStatement) 
```

or

```
2019/01/23 13:56:02.852 [30]  ERROR    PaletteInsightAgent.RepoTablesPoller.RepoPollAgent - Error while polling streaming table: 'http_requests'! Exception:  Exception of type 'System.OutOfMemoryException' was thrown.    at System.String.CreateStringFromEncoding(Byte* bytes, Int32 byteLength, Encoding encoding)
   at System.Text.UTF8Encoding.GetString(Byte[] bytes, Int32 index, Int32 count)
   at Npgsql.NpgsqlBuffer.ReadString(Int32 byteLen)
   at Npgsql.TypeHandlers.TextHandler.Read(String& result)
   at Npgsql.TypeHandler.Read[T](NpgsqlBuffer buf, Int32 len, FieldDescription fieldDescription)
   at Npgsql.TypeHandler.Read[T](DataRowMessage row, Int32 len, FieldDescription fieldDescription)
   at Npgsql.TypeHandler`1.ReadValueAsObject(DataRowMessage row, FieldDescription fieldDescription)
   at Npgsql.NpgsqlDataReader.GetValue(Int32 ordinal)
   at Npgsql.NpgsqlDataReader.GetValues(Object[] values)
   at System.Data.ProviderBase.DataReaderContainer.CommonLanguageSubsetDataReader.GetValues(Object[] values)
   at System.Data.ProviderBase.SchemaMapping.LoadDataRow()
   at System.Data.Common.DataAdapter.FillLoadDataRow(SchemaMapping mapping)
   at System.Data.Common.DataAdapter.FillFromReader(DataSet dataset, DataTable datatable, String srcTable, DataReaderContainer dataReader, Int32 startRecord, Int32 maxRecords, DataColumn parentChapterColumn, Object parentChapterValue)
   at System.Data.Common.DataAdapter.Fill(DataTable[] dataTables, IDataReader dataReader, Int32 startRecord, Int32 maxRecords)
   at System.Data.Common.DbDataAdapter.FillInternal(DataSet dataset, DataTable[] datatables, Int32 startRecord, Int32 maxRecords, String srcTable, IDbCommand command, CommandBehavior behavior)
   at System.Data.Common.DbDataAdapter.Fill(DataTable[] dataTables, Int32 startRecord, Int32 maxRecords, IDbCommand command, CommandBehavior behavior)
   at System.Data.Common.DbDataAdapter.Fill(DataTable dataTable)
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.<>c__DisplayClass11_0.<runQuery>b__0()
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.queryWithReconnect(Func`1 query, Object def, String sqlStatement)
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.runQuery(String query)
   at PaletteInsightAgent.RepoTablesPoller.Tableau9RepoConn.GetStreamingTable(String tableName, RepoTable table, String from, String& newMax)
   at PaletteInsightAgent.RepoTablesPoller.RepoPollAgent.<>c__DisplayClass5_0.<PollStreamingTables>b__1(RepoTable table)
```

#### Solution

*WARNING*: this measurement results in skipping data between our last successful data process and now!

An option to overcome this situation is to look up the latest id from `http_requests` table from the Tableau repository:

```sql
select max(id) from http_requests;
```

Let's say that the result of the query is 44783665. Look up `/data/insight-server/maxids/palette/http_requests` and replace its content to 44783665.

### Repository setup in Config.yml

Connection details and credentials should be under `TableauRepo` key.

Example:

```yml
TableauRepo:
  Host: localhost
  Port: 8060
  Database: workgroup
  User: readonly
  Password: onlyread
```

Tableau repo poll is activated by default and it is being collected from the passive repository node by default. `UseRepoPolling` and `PreferPassiveRepo` keys can alter the default behavior.

Poll from active:

```yml
UseRepoPolling: true
PreferPassiveRepo: false
```

Poll from passive:

```yml
UseRepoPolling: true
PreferPassiveRepo: true
```

NOTE: Config change requires the _RESTART_ of the Agent.

### Tableau setting for repository

Check `connections.yml`.

## Reload the last day (e.g. 2018-12-11)

```sql

-- check load dates
select * from palette.p_load_dates order by 1 desc limit 5;

-- check_if_load_date_already_in_table
select 'p_background_jobs',palette.check_if_load_date_already_in_table('palette', 'p_background_jobs', '2018-12-11', true) union all
select 'p_background_jobs_hourly',palette.check_if_load_date_already_in_table('palette', 'p_background_jobs_hourly', '2018-12-11', true) union all
select 'p_cpu_usage',palette.check_if_load_date_already_in_table('palette', 'p_cpu_usage', '2018-12-11', true) union all
select 'p_cpu_usage_bootstrap_rpt',palette.check_if_load_date_already_in_table('palette', 'p_cpu_usage_bootstrap_rpt', '2018-12-11', true) union all
select 'p_cpu_usage_hourly',palette.check_if_load_date_already_in_table('palette', 'p_cpu_usage_hourly', '2018-12-11', true) union all
select 'p_cpu_usage_report',palette.check_if_load_date_already_in_table('palette', 'p_cpu_usage_report', '2018-12-11', true) union all
select 'p_desktop_session',palette.check_if_load_date_already_in_table('palette', 'p_desktop_session', '2018-12-11', true) union all
select 'p_errorlogs',palette.check_if_load_date_already_in_table('palette', 'p_errorlogs', '2018-12-11', true) union all
select 'p_http_requests',palette.check_if_load_date_already_in_table('palette', 'p_http_requests', '2018-12-11', true) union all
select 'p_interactor_session',palette.check_if_load_date_already_in_table('palette', 'p_interactor_session', '2018-12-11', true) union all
select 'p_load_dates',palette.check_if_load_date_already_in_table('palette', 'p_load_dates', '2018-12-11', true) union all
select 'p_serverlogs',palette.check_if_load_date_already_in_table('palette', 'p_serverlogs', '2018-12-11', true) union all
select 'p_serverlogs_bootstrap_rpt',palette.check_if_load_date_already_in_table('palette', 'p_serverlogs_bootstrap_rpt', '2018-12-11', true) union all
select 't_tde_filename_pids',palette.check_if_load_date_already_in_table('palette', 't_tde_filename_pids', '2018-12-11', true) union all
select 'end',0;

-- count records
select 'p_background_jobs', count(1) from palette.p_background_jobs where created_at > date'2018-12-11' union all
select 'p_cpu_usage' as table_name, count(1) as cnt from palette.p_cpu_usage where ts_rounded_15_secs > date'2018-12-11' union all
select 'p_cpu_usage_hourly', count(1) from palette.p_cpu_usage_hourly where hour > date'2018-12-11' union all
select 'p_cpu_usage_report', count(1) from palette.p_cpu_usage_report where cpu_usage_ts_rounded_15_secs > date'2018-12-11' union all
select 'p_desktop_session', count(1) from palette.p_desktop_session where session_start_ts > date'2018-12-11' union all
select 'p_http_requests', count(1) from palette.p_http_requests where created_at > date'2018-12-11' union all
select 'p_interactor_session', count(1) from palette.p_interactor_session where session_start_ts > date'2018-12-11' union all
select 'p_serverlogs', count(1) from palette.p_serverlogs where start_ts > date'2018-12-11' union all
select 'p_serverlogs_bootstrap_rpt', count(1) from palette.p_serverlogs_bootstrap_rpt where start_ts > date'2018-12-11' union all
select 'p_cpu_usage_bootstrap_rpt', count(1) from palette.p_cpu_usage_bootstrap_rpt where cpu_usage_ts_rounded_15_secs> date'2018-12-11' union all
select 'p_errorlogs', count(1) from palette.p_errorlogs where ts > date'2018-12-11';

-- delete day
delete from palette.p_background_jobs where created_at >= date'2018-12-11';
alter table palette.p_cpu_usage truncate partition "20181211";
alter table palette.p_cpu_usage_report truncate partition "20181211";
alter table palette.p_cpu_usage truncate partition "20181212";
delete from palette.p_cpu_usage_hourly where hour > date'2018-12-11';
alter table palette.p_cpu_usage_report truncate partition "20181212";
delete from palette.p_desktop_session where session_start_ts >= date'2018-12-11';
delete from palette.p_http_requests where created_at >= date'2018-12-11';
delete from palette.p_interactor_session where session_start_ts >= date'2018-12-11';
alter table palette.p_serverlogs truncate partition "20181211";
alter table palette.p_serverlogs_bootstrap_rpt truncate partition "20181211";
delete from palette.p_cpu_usage_bootstrap_rpt where cpu_usage_ts_rounded_15_secs >= date'2018-12-11';
alter table palette.p_errorlogs truncate partition "20181211";


delete from palette.p_load_dates where load_date = date'2018-12-11';
```

## Firewall

In order to test whether the neccessary ports are open on the firewall visit the following page:

```
http://<IP_OR_HOST_OF_INSIGHT_SERVER>
```

and

```
  https://<IP_OR_HOST_OF_INSIGHT_SERVER>/api/v1/ping
```

Please note HTTP and HTTPS respectively.

To open the ports on the firewall use either `lokkit` or `firewalld-cmd`.

### Enable the http/s services on the firewall
We experienced that lokkit is overriding the existing iptables, thus we need to make sure that ssh service will still remain enabled.

```bash
lokkit --service=ssh
lokkit --service=http
lokkit --service=https
lokkit --service=postgresql
```

If firelwallD is enabled, try the following

```bash
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --zone=public --add-service=postgresql
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --zone=public --permanent --add-service=postgresql
```

### Can't connect to Insight Server, because TLS1.2 is not available
If you open the browser on the Tableau Server machine and try to connect to the https://<insight-server-ip-or-name> and it fails with complaining about TLS1.2, you need to modify `/etc/nginx/conf.d/palette-insight-server.conf` and change the `ssl_protocols` and `ssl_ciphers` keys to the following:
```
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
```

And then reload the nginx service by
```bash
sudo service nginx reload
```
