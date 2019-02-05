# Palette Dashboards

## Palette Performace Dashboard

### Average Resource Bottleneck

#### Values

- `Extract`
- `Database`
- `Computed`
- `Dataserver`

The Average Resource Bottleneck is determined by comparing the average wait times accross the selected time interval for a given Tableau Workbook by category. The highest category is choosen.

#### Calculation of average wait times

The calculation is based on factors (`Primary Factor` and `Secondary Factor`) which are determined by parts of the log entry.

```
Avg Extract Wait = SUM(IIF(Contains([Primary Factor],'Extract'),([Elapsed Seconds]),0))/[Session Count]

Avg DB Wait = SUM(IIF(Contains([Primary Factor],'Database'),([Elapsed Seconds]),0))/[Session Count]

Avg Compute Wait = SUM(IIF(Contains([Primary Factor],'Compute'),([Elapsed Seconds]),0))/[Session Count]

Avg Dataserver Wait = SUM(IIF(Contains([Primary Factor],'Dataserver'),([Elapsed Seconds]),0))/[Session Count]
```

#### Primary Factor

The `Primary Factor` of a log entry is determined by the characteristics described in the table below.

| Process Name | Secondary Factor                       | Event Name                             | Primary Factor  |
| ------------ | -------------------------------------- | -------------------------------------- | --------------- |
| tdeserver    |                                        |                                        | Extract         |
|              | Query Extract                          |                                        | Extract         |
|              | Bootstrap                              |                                        | Bootstrap       |
| dataserver   |                                        |                                        | Dataserver      |
| vizqlserver  |                                        | qp-batch-summary                       | Database        |
| vizqlserver  |                                        | end-query                              | Database        |
| tabprotosrv  |                                        |                                        | Combined        |
| vizqlserver  |                                        | read-metadata                          | Database        |
| vizqlserver  |                                        | end-query                              | Database        |
|              | CONTAINS([Secondary Factor],'*')       |                                        | Combined        |
|              | Query Extract                          |                                        | Extract         |
|              |                                        | CONTAINS([Event Name Fixed],'Compute') | Compute         |
|              | CONTAINS([Secondary Factor],'Compute') |                                        | Compute         |
|              | Query Quick Filter                     |                                        | Database        |
|              | Database Query Fusion                  |                                        | Database        |
|              | CONTAINS([Secondary Factor],'DB')      |                                        | Database        |
|              | Database Temp Table                    |                                        | Database        |
|              | Tableau External Query Cache           |                                        | Compute         |
|              | Tableau External Cache                 |                                        | Design          |
|              | Session Created                        |                                        | Session Created |
|              |                                        |                                        | Combined        |

#### Secondary Factor

The `Secondary Factor` used of the determination of the `Primary Factor` are based on the following values of the logs.

| Process Name | Event Name                        | Event Name Fixed    | V contains             | Secondary Factor              |
| ------------ | --------------------------------- | ------------------- | ---------------------- | ----------------------------- |
|              |                                   | compute-percentages |                        | Compute Percentages           |
| tabprotosrv  |                                   |                     |                        | Query DB                      |
| tdeserver    |                                   |                     |                        | Query Extract                 |
|              | read-metadata                     |                     | Hyper                  | Query Extract                 |
|              | read-metadata                     |                     | hyper                  | Query Extract                 |
|              | read-metadata                     |                     | Extract                | Query Extract                 |
|              | read-metadata                     |                     | dataengine             | Query Extract                 |
|              | read-metadata                     |                     | tde                    | Query Extract                 |
| vizqlserver  | end-query                         |                     | Extract                | Query Extract                 |
| vizqlserver  | end-query                         |                     | .tde                   | Query Extract                 |
| vizqlserver  | end-query                         |                     | .hyper                 | Query Extract                 |
| vizqlserver  | end-query                         |                     | "hyper)                | Query Extract                 |
| vizqlserver  | end-query                         |                     | Hyper                  | Query Extract                 |
| dataserver   | end-query                         |                     | Extract                | Query Extract                 |
| dataserver   | end-query                         |                     |                        | Query DB                      |
| vizqlserver  | end-query                         |                     |                        | Query DB                      |
|              | tdeserver                         |                     |                        | Query Extract                 |
|              | read-primary-keys                 |                     |                        | Query DB                      |
|              | read-foreign-keys                 |                     |                        | Query DB                      |
|              | read-statistics                   |                     |                        | Query DB                      |
|              | end-ds-lazy-load-metadata         |                     |                        | Query DB                      |
|              | end-ds-validate-extract           |                     |                        | Query Extract                 |
|              | dataconnection_connect            |                     |                        | Query DB                      |
|              | end-ds-connect                    |                     |                        | Query DB *                    |
|              | end-ds-connect-data-connection    |                     |                        | Query DB *                    |
|              | end-ds-lazy-connect               |                     |                        | Connect DB                    |
|              | end-ds-load-metadata              |                     |                        | Load DB Metadata              |
|              | end-ds-parser-connect             |                     |                        | Connect Parser DB *           |
|              | end-ds-parser-connect-extract     |                     |                        | Connect Parser Extract        |
|              | end-ds-validate                   |                     |                        | Query DB *                    |
|              | process_query                     |                     |                        | Query DB                      |
|              | compute-x-axis-descriptor         |                     |                        | Compute Axis                  |
|              | compute-x-set-interp              |                     |                        | Compute Axis                  |
|              | compute-y-axis-descriptor         |                     |                        | Compute Axis                  |
|              | compute-y-set-interp              |                     |                        | Compute Axis                  |
|              | generate-axis-encodings           |                     |                        | Compute Axis                  |
|              | end-bootstrap-session             |                     |                        | Bootstrap                     |
|              | end-wimage-compute-layout         |                     |                        | Build Visual Model            |
|              | end-wimage-compute-vmodel         |                     |                        | Build Visual Model            |
|              | end-compute-quick-filter-state    |                     |                        | Compute Quick Filters         |
|              | end-data-interpreter              |                     |                        | Compute Data                  |
|              | end-partition-interpreter         |                     |                        | Compute Data                  |
|              | end-prepare-primary-mapping-table |                     |                        | Compute Data                  |
|              | end-update-sheet                  |                     |                        | Compute Data                  |
|              | end-visual-interpreter            |                     |                        | Compute Data                  |
|              | partition-data                    |                     |                        | Compute Data                  |
|              | set-collation                     |                     |                        | Compute Data                  |
|              | end-prepare-quick-filter-queries  |                     |                        | Compute Prepare Quick Filters |
|              | end-sql-temp-table-tuples-create  |                     |                        | Compute Internal Temp Table   |
|              | eqc-load                          |                     |                        | Tableau External Query Cache  |
|              | eqc-log-cache-key                 |                     |                        | Tableau External Query Cache  |
|              | eqc-store                         |                     |                        | Tableau External Query Cache  |
|              | qp-info                           |                     |                        | Query DB                      |
|              | qp-optimize-dependencies          |                     |                        | Query DB                      |
|              | qp-query-end                      |                     | QuickFiltersController | Query DB Quick Filter         |
|              | qp-query-end                      |                     |                        | Compute Query Fusion          |
|              | qp-query-fusion                   |                     |                        | Compute Query Fusion          |
|              | ec-drop                           |                     |                        | Tableau External Cache        |
|              | ec-load                           |                     |                        | Tableau External Cache        |
|              | ec-store                          |                     |                        | Tableau External Cache        |
|              | sort-panes                        |                     |                        | Compute Sort                  |
|              | zlib-compress-data                |                     |                        | Compute Compression           |
|              | zlib-uncompress-data              |                     |                        | Compute Compression           |
|              | end-prepare-mapping-tables        |                     |                        | Compute Mapping Tables        |
|              | end-secondarydsinterpreter-apply  |                     |                        | Compute Interpretter          |
|              | lock-session                      |                     |                        | Session Created               |
|              | end-bootstrap-session             |                     |                        | Bootstrap                     |
|              | Query Fusion                      |                     |                        | Query DB                      |
