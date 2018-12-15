# Troubleshooting for Palette Insight

## Check installed datamodel version

For example you can acces the Greenplum database via this shell command:
```bash
psql -d palette -h 127.0.0.1 -U readonly
```
and then execute the following statement:
```sql
select *
from
    palette.db_version_meta
order by 1 desc
limit 1
;
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


### Reload the last day (e.g. 2018-12-11)
```sql
select * from palette.p_load_dates order by 1 desc limit 5;

select 'p_cpu_usage' as table_name, count(1) as cnt from palette.p_cpu_usage where ts_rounded_15_secs > date'2018-12-11' union all
select 'p_cpu_usage_report', count(1) from palette.p_cpu_usage_report where cpu_usage_ts_rounded_15_secs > date'2018-12-11' union all
select 'p_desktop_session', count(1) from palette.p_desktop_session where session_start_ts > date'2018-12-11' union all
select 'p_interactor_session', count(1) from palette.p_interactor_session where session_start_ts > date'2018-12-11' union all
select 'p_serverlogs_bootstrap_rpt', count(1) from palette.p_serverlogs_bootstrap_rpt where start_ts > date'2018-12-11' union all
select 'p_cpu_usage_bootstrap_rpt', count(1) from palette.p_cpu_usage_bootstrap_rpt where cpu_usage_ts_rounded_15_secs> date'2018-12-11' union all
select 'p_errorlogs', count(1) from palette.p_errorlogs where ts > date'2018-12-11';


alter table palette.p_cpu_usage truncate partition "20181211";
alter table palette.p_cpu_usage_report truncate partition "20181211";
alter table palette.p_cpu_usage truncate partition "20181212";
alter table palette.p_cpu_usage_report truncate partition "20181212";
delete from palette.p_desktop_session where session_start_ts >= date'2018-12-11';
delete from palette.p_interactor_session where session_start_ts >= date'2018-12-11';
alter table palette.p_serverlogs_bootstrap_rpt truncate partition "20181211";
delete from palette.p_cpu_usage_bootstrap_rpt where cpu_usage_ts_rounded_15_secs >= date'2018-12-11';
alter table palette.p_errorlogs truncate partition "20181211";

delete from palette.p_load_dates where load_date = date'2018-12-11';
```
