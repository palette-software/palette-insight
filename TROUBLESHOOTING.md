# Troubleshooting for Palette Insight

## Check installed datamodel version

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

### Repository setup in Config.yaml

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

Poll is activated by `UseRepoPolling` and `PreferPassiveRepo`.

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
