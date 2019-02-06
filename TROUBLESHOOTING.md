# Troubleshooting for Palette Insight

## Access the Palette Database locally on the Palette Server

You can access the Greenplum database via this shell command:

```bash
psql -h 127.0.0.1 -d palette -U readonly
```

or

```bash
psql -h 127.0.0.1 -d palette -U palette
```

## Check installed datamodel version

```sql
select *
from
    palette.db_version_meta
order by 1 desc
limit 1
;
```

## Performance dashboard missing data

### Check the last sessions that should show up in the Performance dashboard

The table `p_interactor_session_normal` is feeding the Performance dashboard.
```sql
select * from palette.p_interactor_session_normal order by session_start_ts desc limit 10;
```

### Datasource extracts are failing because of timeout (7200 seconds)

#### Check the size of the tables

```sql
select count(1) from palette.p_cpu_usage_bootstrap_rpt;
select count(1) from palette.p_serverlogs_bootstrap_rpt;
select count(1) from palette.p_interactor_session;
```

#### Drop archive data

```sql
alter table palette.p_interactor_session drop partition "2018";
```

## Repository polling

### Logs

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

### Insight has fallen too much behind in processing one ore more Tableau repo tables
If you have a feeling or proof that any of the Tableau repo tables is not being fetched properly, then you can take the following measurement. *WARNING*: this measurement results in skipping data between our last successful data process and now!

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
