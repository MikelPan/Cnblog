### 查询语句
1、查看每个客户端IP过来的连接消耗了多少资源
```sql
select * from sys.x$host_summary;
+---------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
| host          | statements | statement_latency | statement_avg_latency | table_scans | file_ios | file_io_latency | current_connections | total_connections | unique_users | current_memory | total_memory_allocated |
+---------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
| 116.30.139.76 |          3 |       37562573000 |      12520857666.6667 |           2 |       36 |      5110255200 |                   1 |                 1 |            1 |              0 |                      0 |
| 172.17.0.1    |    1235334 |   882736374590000 |        714573042.2623 |        4384 |     3986 |  15205475400000 |                   0 |            118768 |            2 |              0 |                      0 |
| 172.18.77.102 |          2 |         473014000 |        236507000.0000 |           1 |       28 |      2546547200 |                   1 |                 1 |            1 |              0 |                      0 |
+---------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
```
2、查看某个数据文件上发生了多少IO请求。
```sql
select * from sys.x$io_global_by_file_by_bytes;
```
3、查看每个用户消耗了多少资源
```sql
+------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
| user       | statements | statement_latency | statement_avg_latency | table_scans | file_ios | file_io_latency | current_connections | total_connections | unique_hosts | current_memory | total_memory_allocated |
+------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
| gitea      |     568359 |   372867490767000 |        656042203.5492 |        2182 |     1756 |   6372235120000 |                   1 |             94676 |            1 |              0 |                      0 |
| drone      |      49422 |    68515406520000 |       1386334153.2111 |          10 |      237 |   1230502580000 |                   0 |             24118 |            1 |              0 |                      0 |
| root       |         14 |      120585964000 |       8613283142.8571 |          10 |      198 |     20893982400 |                   2 |                 2 |            2 |              0 |                      0 |
| background |          0 |                 0 |                0.0000 |           0 |    75802 |  25818893324000 |                  25 |                84 |            0 |              0 |                      0 |
+------------+------------+-------------------+-----------------------+-------------+----------+-----------------+---------------------+-------------------+--------------+----------------+------------------------+
4 rows in set (0.01 sec)
```
4、查看总共分配了多少内存
```sql
+-----------------+
| total_allocated |
+-----------------+
|       150716424 |
+-----------------+
```
5、数据库连接来自哪里，以及这些连接对数据库的请求情况是怎样的？ 查看当前连接情况。
```sql
+---------------+---------------------+------------+
| host          | current_connections | statements |
+---------------+---------------------+------------+
| 116.30.139.76 |                   1 |          3 |
| 172.17.0.1    |                   0 |    1235758 |
| 172.18.77.102 |                   1 |          6 |
+---------------+---------------------+------------+
3 rows in set (0.01 sec)
```
6、查看当前正在执行的SQL和执行show full processlist的效果相当。
```sql
+---------+--------------------+---------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
| conn_id | user               | current_statement                                                                                       | last_statement                                                                                          |
+---------+--------------------+---------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
|  118813 | root@116.30.139.76 | SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA | SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA |
|  118825 | root@172.18.77.102 | select conn_id, user, current_statement, last_statement from sys.x$session                              | NULL                                                                                                    |
+---------+--------------------+---------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
2 rows in set (0.04 sec)
```
7、数据库中哪些SQL被频繁执行？ 执行下面命令查询TOP10 SQL。
```sql
select db,exec_count,query from sys.x$statement_analysis order by exec_count desc limit 10 \G
*************************** 1. row ***************************
        db: gitea
exec_count: 94707
     query: SET NAMES `utf8` 
*************************** 2. row ***************************
        db: drone
exec_count: 23474
     query: SELECT `stage_id` , `stage_repo_id` , `stage_build_id` , `stage_number` , `stage_name` , `stage_kind` , `stage_type` , `stage_status` , `stage_error` , `stage_errignore` , `stage_exit_code` , `stage_limit` , `stage_limit_repo` , `stage_os` , `stage_arch` , `stage_variant` , `stage_kernel` , `stage_machine` , `stage_started` , `stage_stopped` , `stage_created` , `stage_updated` , `stage_version` , `stage_on_success` , `stage_on_failure` , `stage_depends_on` , `stage_labels` FROM `stages` WHERE `stage_id` IN ( SELECT `stage_id` FROM `stages_unfinished` ) AND `stage_status` IN (...) ORDER BY `stage_id` ASC 
*************************** 3. row ***************************
        db: gitea
exec_count: 36
     query: START TRANSACTION 
*************************** 4. row ***************************
        db: gitea
exec_count: 34
     query: COMMIT 
*************************** 5. row ***************************
        db: drone
exec_count: 20
     query: SELECT `build_id` , `build_repo_id` , `build_trigger` , `build_number` , `build_parent` , `build_status` , `build_error` , `build_event` , `build_action` , `build_link` , `build_timestamp` , `build_title` , `build_message` , `build_before` , `build_after` , `build_ref` , `build_source_repo` , `build_source` , `build_target` , `build_author` , `build_author_name` , `build_author_email` , `build_author_avatar` , `build_sender` , `build_params` , `build_cron` , `build_deploy` , `build_deploy_id` , `build_debug` , `build_started` , `build_finished` , `build_created` , `build_updated` , `build_version` FROM `builds` WHERE EXISTS ( SELECT `stage_id` FROM `stages` WHERE `stages` . `stage_build_id` = `builds` . `build_id` AND `stages` . `stage_status` = ? ) ORDER BY `build_id` ASC 
*************************** 6. row ***************************
        db: gitea
exec_count: 12
     query: SELECT `repo` . `id` FROM `repository` `repo` WHERE `repo` . `num_watches` != ( SELECT COUNT ( * ) FROM `watch` WHERE `repo_id` = `repo` . `id` AND MODE != ? ) 
*************************** 7. row ***************************
        db: gitea
exec_count: 12
     query: SELECT `id` , `owner_id` , `owner_name` , `lower_name` , `name` , `description` , `website` , `original_service_type` , `original_url` , `default_branch` , `num_watches` , `num_stars` , `num_forks` , `num_issues` , `num_closed_issues` , `num_pulls` , `num_closed_pulls` , `num_milestones` , `num_closed_milestones` , `num_projects` , `num_closed_projects` , `is_private` , `is_empty` , `is_archived` , `is_mirror` , `status` , `is_fork` , `fork_id` , `is_template` , `template_id` , `size` , `is_fsck_enabled` , `close_issues_via_commit_in_any_branch` , `topics` , `trust_model` , `avatar` , `created_unix` , `updated_unix` FROM `repository` WHERE ( `id` > ? ) 
*************************** 8. row ***************************
        db: gitea
exec_count: 12
     query: SELECT `repo` . `id` FROM `repository` `repo` WHERE `repo` . `num_stars` != ( SELECT COUNT ( * ) FROM `star` WHERE `repo_id` = `repo` . `id` ) 
*************************** 9. row ***************************
        db: gitea
exec_count: 12
     query: SELECT `label` . `id` FROM `label` WHERE `label` . `num_issues` != ( SELECT COUNT ( * ) FROM `issue_label` WHERE `label_id` = `label` . `id` ) 
*************************** 10. row ***************************
        db: gitea
exec_count: 12
     query: SELECT `user` . `id` FROM `user` WHERE `user` . `num_repos` != ( SELECT COUNT ( * ) FROM `repository` WHERE `owner_id` = `user` . `id` ) 
10 rows in set (0.01 sec)
```
8、哪个文件产生了最多的IO，读多，还是写的多
```sql
select * from sys.x$io_global_by_file_by_bytes limit 10;
+---------------------------------------------+------------+------------+------------+-------------+---------------+------------+------------+-----------+
| file                                        | count_read | total_read | avg_read   | count_write | total_written | avg_write  | total      | write_pct |
+---------------------------------------------+------------+------------+------------+-------------+---------------+------------+------------+-----------+
| /var/lib/mysql/ibtmp1                       |          0 |          0 |     0.0000 |       70493 |    1167343616 | 16559.7097 | 1167343616 |    100.00 |
| /var/lib/mysql/ibdata1                      |        379 |    8323072 | 21960.6121 |         973 |      38174720 | 39234.0391 |   46497792 |     82.10 |
| /var/lib/mysql/gitea/action.ibd             |         35 |     622592 | 17788.3429 |         148 |       2424832 | 16384.0000 |    3047424 |     79.57 |
| /var/lib/mysql/gitea/hook_task.ibd          |         19 |     360448 | 18970.9474 |         162 |       2654208 | 16384.0000 |    3014656 |     88.04 |
| /var/lib/mysql/ib_logfile0                  |          7 |      70144 | 10020.5714 |         652 |       1225728 |  1879.9509 |    1295872 |     94.59 |
| /var/lib/mysql/mysql/innodb_index_stats.ibd |         21 |     393216 | 18724.5714 |          48 |        786432 | 16384.0000 |    1179648 |     66.67 |
| /var/lib/mysql/gitea/notice.ibd             |         14 |     278528 | 19894.8571 |          50 |        819200 | 16384.0000 |    1097728 |     74.63 |
| /var/lib/mysql/gitea/repository.ibd         |         20 |     376832 | 18841.6000 |          34 |        557056 | 16384.0000 |     933888 |     59.65 |
| /var/lib/mysql/gitea/webhook.ibd            |         10 |     212992 | 21299.2000 |          34 |        557056 | 16384.0000 |     770048 |     72.34 |
| /var/lib/mysql/mysql/innodb_table_stats.ibd |          4 |     114688 | 28672.0000 |          25 |        409600 | 16384.0000 |     524288 |     78.13 |
+---------------------------------------------+------------+------------+------------+-------------+---------------+------------+------------+-----------+
10 rows in set (0.00 sec)

```
9、哪个表上的IO请求最多？
```sql
select * from sys.x$io_global_by_file_by_bytes where file like "%ibd" order by total desc limit 10;
+----------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
| file                                         | count_read | total_read | avg_read   | count_write | total_written | avg_write  | total   | write_pct |
+----------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
| /var/lib/mysql/gitea/action.ibd              |         35 |     622592 | 17788.3429 |         148 |       2424832 | 16384.0000 | 3047424 |     79.57 |
| /var/lib/mysql/gitea/hook_task.ibd           |         19 |     360448 | 18970.9474 |         162 |       2654208 | 16384.0000 | 3014656 |     88.04 |
| /var/lib/mysql/mysql/innodb_index_stats.ibd  |         21 |     393216 | 18724.5714 |          48 |        786432 | 16384.0000 | 1179648 |     66.67 |
| /var/lib/mysql/gitea/notice.ibd              |         14 |     278528 | 19894.8571 |          50 |        819200 | 16384.0000 | 1097728 |     74.63 |
| /var/lib/mysql/gitea/repository.ibd          |         20 |     376832 | 18841.6000 |          34 |        557056 | 16384.0000 |  933888 |     59.65 |
| /var/lib/mysql/gitea/webhook.ibd             |         10 |     212992 | 21299.2000 |          34 |        557056 | 16384.0000 |  770048 |     72.34 |
| /var/lib/mysql/mysql/innodb_table_stats.ibd  |          4 |     114688 | 28672.0000 |          25 |        409600 | 16384.0000 |  524288 |     78.13 |
| /var/lib/mysql/gitea/language_stat.ibd       |          7 |     163840 | 23405.7143 |          17 |        278528 | 16384.0000 |  442368 |     62.96 |
| /var/lib/mysql/gitea/public_key.ibd          |          4 |     114688 | 28672.0000 |          20 |        327680 | 16384.0000 |  442368 |     74.07 |
| /var/lib/mysql/gitea/repo_indexer_status.ibd |          7 |     163840 | 23405.7143 |          17 |        278528 | 16384.0000 |  442368 |     62.96 |
+----------------------------------------------+------------+------------+------------+-------------+---------------+------------+---------+-----------+
10 rows in set (0.00 sec)
```
10、哪个表被访问的最多？ 先访问statement_analysis，根据热门SQL排序找到相应的数据表。 哪些语句延迟比较严重？ 查看statement_analysis中avg_latency的最高的SQL。
```sql
select * from sys.x$statement_analysis order by avg_latency desc limit 10;
*************************** 1. row ***************************
            query: CREATE TABLE IF NOT EXISTS `migrations` ( NAME VARCHARACTER (?) , UNIQUE ( NAME ) ) 
               db: drone
        full_scan: 
       exec_count: 3
        err_count: 0
       warn_count: 3
    total_latency: 281286943000
      max_latency: 214550853000
      avg_latency: 93762314000
     lock_latency: 0
        rows_sent: 0
    rows_sent_avg: 0
    rows_examined: 0
rows_examined_avg: 0
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 0
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: 53d9a6ef48ecf2f0fd32d1987715070c
       first_seen: 2021-10-11 01:47:37
        last_seen: 2021-10-11 03:57:32
*************************** 2. row ***************************
            query: SELECT `t` . `THREAD_ID` AS `thread_id` , IF ( ( `t` . `NAME` = ? ) , `concat` ( `t` . `PROCESSLIST_USER` , ? , `t` . `PROCESSLIST_HOST` ) , REPLACE ( `t` . `NAME` , ?, ... ) ) AS `user` , SUM ( `mt` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `mt` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `mt` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM ( `performance_schema` . `memory_summary_by_thread_by_event_name` `mt` JOIN `performance_schema` . `threads` `t` ON ( ( `mt` . `THREAD_ID` = `t` . `THREAD_ID` ) ) ) GROUP BY `t` . `THREAD_ID` , IF ( ( `t` . `NAME` = ? ) , `concat` ( `t` . `PROCESSLIST_USER` , ? , `t` . `PROCESSLIST_HOST` ) , REPLACE ( `t` . `NAME` , ?, ... ) ) ORDER BY SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) DESC 
               db: NULL
        full_scan: *
       exec_count: 1
        err_count: 0
       warn_count: 0
    total_latency: 34761894000
      max_latency: 34761894000
      avg_latency: 34761894000
     lock_latency: 2449000000
        rows_sent: 2
    rows_sent_avg: 2
    rows_examined: 8060
rows_examined_avg: 8060
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 4
  tmp_disk_tables: 2
      rows_sorted: 54
sort_merge_passes: 0
           digest: b3ea91361b876a2dba55fdce3df2ee23
       first_seen: 2021-10-21 22:59:08
        last_seen: 2021-10-21 22:59:08
*************************** 3. row ***************************
            query: SELECT `repo` . `id` FROM `repository` `repo` WHERE `repo` . `num_watches` != ( SELECT COUNT ( * ) FROM `watch` WHERE `repo_id` = `repo` . `id` AND MODE != ? ) 
               db: gitea
        full_scan: *
       exec_count: 12
        err_count: 0
       warn_count: 0
    total_latency: 348517977000
      max_latency: 94577727000
      avg_latency: 29043164000
     lock_latency: 340011000000
        rows_sent: 0
    rows_sent_avg: 0
    rows_examined: 1872
rows_examined_avg: 156
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 0
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: 8374e1794ccb5735edb911a5fe797ac2
       first_seen: 2021-10-11 01:48:02
        last_seen: 2021-10-21 03:57:34
*************************** 4. row ***************************
            query: SELECT NAME FROM `migrations` 
               db: drone
        full_scan: 
       exec_count: 3
        err_count: 0
       warn_count: 0
    total_latency: 82525140000
      max_latency: 81626911000
      avg_latency: 27508380000
     lock_latency: 599000000
        rows_sent: 126
    rows_sent_avg: 42
    rows_examined: 126
rows_examined_avg: 42
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 0
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: b33a7810857e9fc943adcceff8b50eee
       first_seen: 2021-10-11 01:47:38
        last_seen: 2021-10-11 03:57:32
*************************** 5. row ***************************
            query: SHOW VARIABLES LIKE ? 
               db: NULL
        full_scan: *
       exec_count: 1
        err_count: 0
       warn_count: 0
    total_latency: 26433246000
      max_latency: 26433246000
      avg_latency: 26433246000
     lock_latency: 11643000000
        rows_sent: 2
    rows_sent_avg: 2
    rows_examined: 1038
rows_examined_avg: 1038
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 1
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: 6909bda371af7c36751d55c3ca80a467
       first_seen: 2021-10-21 22:51:04
        last_seen: 2021-10-21 22:51:04
*************************** 6. row ***************************
            query: SELECT `repo` . `id` FROM `repository` `repo` WHERE `repo` . `num_forks` != ( SELECT COUNT ( * ) FROM `repository` WHERE `fork_id` = `repo` . `id` ) 
               db: gitea
        full_scan: *
       exec_count: 12
        err_count: 0
       warn_count: 0
    total_latency: 166652237000
      max_latency: 83226615000
      avg_latency: 13887686000
     lock_latency: 84171000000
        rows_sent: 0
    rows_sent_avg: 0
    rows_examined: 144
rows_examined_avg: 12
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 0
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: b20267e1d993b388dd5faf0169c7540d
       first_seen: 2021-10-11 01:48:03
        last_seen: 2021-10-21 03:57:34
*************************** 7. row ***************************
            query: SELECT SCHEMA_NAME , `DEFAULT_CHARACTER_SET_NAME` , `DEFAULT_COLLATION_NAME` FROM `information_schema` . `SCHEMATA` 
               db: NULL
        full_scan: *
       exec_count: 1
        err_count: 0
       warn_count: 0
    total_latency: 10995546000
      max_latency: 10995546000
      avg_latency: 10995546000
     lock_latency: 158000000
        rows_sent: 9
    rows_sent_avg: 9
    rows_examined: 9
rows_examined_avg: 9
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 1
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: b49bd9b5e098ddae13add2d25c8605b3
       first_seen: 2021-10-21 22:51:04
        last_seen: 2021-10-21 22:51:04
*************************** 8. row ***************************
            query: SELECT IF ( `isnull` ( `performance_schema` . `memory_summary_by_host_by_event_name` . `HOST` ) , ? , `performance_schema` . `memory_summary_by_host_by_event_name` . `HOST` ) AS `host` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM `performance_schema` . `memory_summary_by_host_by_event_name` GROUP BY 
               db: NULL
        full_scan: *
       exec_count: 2
        err_count: 0
       warn_count: 0
    total_latency: 21206708000
      max_latency: 13711231000
      avg_latency: 10603354000
     lock_latency: 4087000000
        rows_sent: 6
    rows_sent_avg: 3
    rows_examined: 6512
rows_examined_avg: 3256
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 16
  tmp_disk_tables: 0
      rows_sorted: 32
sort_merge_passes: 0
           digest: 515d59bbe7c335f0f9419c58fcd2e7fc
       first_seen: 2021-10-21 22:51:59
        last_seen: 2021-10-21 22:58:11
*************************** 9. row ***************************
            query: SELECT IF ( `isnull` ( `performance_schema` . `memory_summary_by_user_by_event_name` . `USER` ) , ? , `performance_schema` . `memory_summary_by_user_by_event_name` . `USER` ) AS `user` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM `performance_schema` . `memory_summary_by_user_by_event_name` GROUP BY 
               db: NULL
        full_scan: *
       exec_count: 1
        err_count: 0
       warn_count: 0
    total_latency: 9883680000
      max_latency: 9883680000
      avg_latency: 9883680000
     lock_latency: 2935000000
        rows_sent: 4
    rows_sent_avg: 4
    rows_examined: 3269
rows_examined_avg: 3269
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 9
  tmp_disk_tables: 0
      rows_sorted: 21
sort_merge_passes: 0
           digest: acbdb01b824436de1a67af3424fcd0c1
       first_seen: 2021-10-21 22:55:25
        last_seen: 2021-10-21 22:55:25
*************************** 10. row ***************************
            query: SELECT COUNT ( * ) FROM `builds` 
               db: drone
        full_scan: 
       exec_count: 10
        err_count: 0
       warn_count: 0
    total_latency: 90215332000
      max_latency: 88410662000
      avg_latency: 9021533000
     lock_latency: 88328000000
        rows_sent: 10
    rows_sent_avg: 1
    rows_examined: 1190
rows_examined_avg: 119
    rows_affected: 0
rows_affected_avg: 0
       tmp_tables: 0
  tmp_disk_tables: 0
      rows_sorted: 0
sort_merge_passes: 0
           digest: c73d296c91a346fcb2396cd70f3c0181
       first_seen: 2021-10-12 00:00:00
        last_seen: 2021-10-21 00:00:00
10 rows in set (0.00 sec)
```
11、哪些SQL执行了全表扫描，如果没有使用索引，则考虑为大型表添加索引
```sql
select * from sys.x$statements_with_full_table_scans;
```
12、列出所有做过排序的规范化语句
```sql
 select * from sys.x$statements_with_sorting
```
13、哪些SQL语句使用了临时表，又有哪些用到了磁盘临时表？ 查看statement_analysis中哪个SQL的tmp_tables 、tmp_disk_tables值大于0即可
```sql
select db, query, tmp_tables, tmp_disk_tables from sys.x$statement_analysis where tmp_tables>0 or tmp_disk_tables >0 order by (tmp_tables+tmp_disk_tables) desc limit 20;
*************************** 1. row ***************************
             db: drone
          query: SELECT `stage_id` , `stage_repo_id` , `stage_build_id` , `stage_number` , `stage_name` , `stage_kind` , `stage_type` , `stage_status` , `stage_error` , `stage_errignore` , `stage_exit_code` , `stage_limit` , `stage_limit_repo` , `stage_os` , `stage_arch` , `stage_variant` , `stage_kernel` , `stage_machine` , `stage_started` , `stage_stopped` , `stage_created` , `stage_updated` , `stage_version` , `stage_on_success` , `stage_on_failure` , `stage_depends_on` , `stage_labels` FROM `stages` WHERE `stage_id` IN ( SELECT `stage_id` FROM `stages_unfinished` ) AND `stage_status` IN (...) ORDER BY `stage_id` ASC 
     tmp_tables: 23497
tmp_disk_tables: 23497
*************************** 2. row ***************************
             db: NULL
          query: SELECT IF ( `isnull` ( `performance_schema` . `memory_summary_by_host_by_event_name` . `HOST` ) , ? , `performance_schema` . `memory_summary_by_host_by_event_name` . `HOST` ) AS `host` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `performance_schema` . `memory_summary_by_host_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `performance_schema` . `memory_summary_by_host_by_event_name` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM `performance_schema` . `memory_summary_by_host_by_event_name` GROUP BY 
     tmp_tables: 16
tmp_disk_tables: 0
*************************** 3. row ***************************
             db: NULL
          query: SELECT IF ( `isnull` ( `performance_schema` . `memory_summary_by_user_by_event_name` . `USER` ) , ? , `performance_schema` . `memory_summary_by_user_by_event_name` . `USER` ) AS `user` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `performance_schema` . `memory_summary_by_user_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `performance_schema` . `memory_summary_by_user_by_event_name` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM `performance_schema` . `memory_summary_by_user_by_event_name` GROUP BY 
     tmp_tables: 9
tmp_disk_tables: 0
*************************** 4. row ***************************
             db: NULL
          query: SELECT `t` . `THREAD_ID` AS `thread_id` , IF ( ( `t` . `NAME` = ? ) , `concat` ( `t` . `PROCESSLIST_USER` , ? , `t` . `PROCESSLIST_HOST` ) , REPLACE ( `t` . `NAME` , ?, ... ) ) AS `user` , SUM ( `mt` . `CURRENT_COUNT_USED` ) AS `current_count_used` , SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_allocated` , `ifnull` ( ( SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) / `nullif` ( SUM ( `mt` . `CURRENT_COUNT_USED` ) , ? ) ) , ? ) AS `current_avg_alloc` , MAX ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `current_max_alloc` , SUM ( `mt` . `SUM_NUMBER_OF_BYTES_ALLOC` ) AS `total_allocated` FROM ( `performance_schema` . `memory_summary_by_thread_by_event_name` `mt` JOIN `performance_schema` . `threads` `t` ON ( ( `mt` . `THREAD_ID` = `t` . `THREAD_ID` ) ) ) GROUP BY `t` . `THREAD_ID` , IF ( ( `t` . `NAME` = ? ) , `concat` ( `t` . `PROCESSLIST_USER` , ? , `t` . `PROCESSLIST_HOST` ) , REPLACE ( `t` . `NAME` , ?, ... ) ) ORDER BY SUM ( `mt` . `CURRENT_NUMBER_OF_BYTES_USED` ) DESC 
     tmp_tables: 4
tmp_disk_tables: 2
*************************** 5. row ***************************
             db: NULL
          query: SHOW VARIABLES LIKE ? 
     tmp_tables: 1
tmp_disk_tables: 0
*************************** 6. row ***************************
             db: NULL
          query: SELECT SCHEMA_NAME , `DEFAULT_CHARACTER_SET_NAME` , `DEFAULT_COLLATION_NAME` FROM `information_schema` . `SCHEMATA` 
     tmp_tables: 1
tmp_disk_tables: 0
*************************** 7. row ***************************
             db: NULL
          query: SHOW SCHEMAS 
     tmp_tables: 1
tmp_disk_tables: 0
*************************** 8. row ***************************
             db: NULL
          query: SELECT SUM ( `performance_schema` . `memory_summary_global_by_event_name` . `CURRENT_NUMBER_OF_BYTES_USED` ) AS `total_allocated` FROM `performance_schema` . `memory_summary_global_by_event_name` 
     tmp_tables: 1
tmp_disk_tables: 0
8 rows in set (0.00 sec)
```
14、列出所有使用临时表的语句——访问最高的磁盘临时表，然后访问内存临时表
```sql
select * from sys.statements_with_temp_tables;
+-------------------------------------------------------------------+-------+------------+---------------+-------------------+-----------------+--------------------------+------------------------+---------------------+---------------------+----------------------------------+
| query                                                             | db    | exec_count | total_latency | memory_tmp_tables | disk_tmp_tables | avg_tmp_tables_per_query | tmp_tables_to_disk_pct | first_seen          | last_seen           | digest                           |
+-------------------------------------------------------------------+-------+------------+---------------+-------------------+-----------------+--------------------------+------------------------+---------------------+---------------------+----------------------------------+
| SELECT `stage_id` , `stage_rep ... (...) ORDER BY `stage_id` ASC  | drone |      23500 | 1.08 m        |             23500 |           23500 |                        1 |                    100 | 2021-10-11 01:48:16 | 2021-10-21 23:17:27 | 19c89ba6aa15e67fb3e8cc306b8334e9 |
| SELECT `t` . `THREAD_ID` AS `t ... _NUMBER_OF_BYTES_USED` ) DESC  | NULL  |          1 | 34.76 ms      |                 4 |               2 |                        4 |                     50 | 2021-10-21 22:59:08 | 2021-10-21 22:59:08 | b3ea91361b876a2dba55fdce3df2ee23 |
| SELECT IF ( `isnull` ( `perfor ... _host_by_event_name` GROUP BY  | NULL  |          2 | 21.21 ms      |                16 |               0 |                        8 |                      0 | 2021-10-21 22:51:59 | 2021-10-21 22:58:11 | 515d59bbe7c335f0f9419c58fcd2e7fc |
| SELECT IF ( `isnull` ( `perfor ... _user_by_event_name` GROUP BY  | NULL  |          1 | 9.88 ms       |                 9 |               0 |                        9 |                      0 | 2021-10-21 22:55:25 | 2021-10-21 22:55:25 | acbdb01b824436de1a67af3424fcd0c1 |
| SHOW VARIABLES LIKE ?                                             | NULL  |          1 | 26.43 ms      |                 1 |               0 |                        1 |                      0 | 2021-10-21 22:51:04 | 2021-10-21 22:51:04 | 6909bda371af7c36751d55c3ca80a467 |
| SELECT SCHEMA_NAME , `DEFAULT_ ... ormation_schema` . `SCHEMATA`  | NULL  |          1 | 11.00 ms      |                 1 |               0 |                        1 |                      0 | 2021-10-21 22:51:04 | 2021-10-21 22:51:04 | b49bd9b5e098ddae13add2d25c8605b3 |
| SHOW SCHEMAS                                                      | NULL  |          1 | 347.73 us     |                 1 |               0 |                        1 |                      0 | 2021-10-21 22:51:45 | 2021-10-21 22:51:45 | 6d711d488f3ed491a0d7610aa0d65038 |
| SELECT SUM ( `performance_sche ... summary_global_by_event_name`  | NULL  |          1 | 1.46 ms       |                 1 |               0 |                        1 |                      0 | 2021-10-21 22:56:52 | 2021-10-21 22:56:52 | 72689c483398f8adc8bded2a8c063811 |
+-------------------------------------------------------------------+-------+------------+---------------+-------------------+-----------------+--------------------------+------------------------+---------------------+---------------------+----------------------------------+
8 rows in set (0.01 sec)
```
15、哪个表占用了最多的buffer pool？
```sql
select * from sys.x$innodb_buffer_stats_by_table order by allocated desc limit 10;
+---------------+---------------------------+-----------+--------+-------+--------------+-----------+-------------+
| object_schema | object_name               | allocated | data   | pages | pages_hashed | pages_old | rows_cached |
+---------------+---------------------------+-----------+--------+-------+--------------+-----------+-------------+
| gitea         | action                    |    524288 | 436567 |    32 |           16 |        10 |         706 |
| mysql         | innodb_index_stats        |    294912 | 139614 |    18 |            7 |         5 |        1345 |
| gitea         | hook_task                 |    278528 |  98785 |    17 |            0 |         5 |          20 |
| gitea         | repository                |    262144 |   5909 |    16 |            3 |         7 |          12 |
| gitea         | commit_status             |    196608 |  68643 |    12 |            0 |         2 |         228 |
| mysql         | time_zone_name            |    180224 | 111078 |    11 |            0 |         0 |        1279 |
| gitea         | notice                    |    163840 |  87700 |    10 |            0 |         6 |         808 |
| gitea         | reaction                  |    147456 |      0 |     9 |            0 |         0 |           0 |
| mysql         | time_zone_transition      |    147456 | 125958 |     9 |            0 |         3 |        3814 |
| mysql         | time_zone_transition_type |    147456 | 117219 |     9 |            0 |         1 |        2946 |
+---------------+---------------------------+-----------+--------+-------+--------------+-----------+-------------+
10 rows in set (0.04 sec)

```
16、每个库（database）占用多少buffer pool？
```sql
select * from sys.x$innodb_buffer_stats_by_schema order by allocated desc limit 10;
+---------------+-----------+---------+-------+--------------+-----------+-------------+
| object_schema | allocated | data    | pages | pages_hashed | pages_old | rows_cached |
+---------------+-----------+---------+-------+--------------+-----------+-------------+
| gitea         |   3768320 |  729270 |   230 |           23 |        62 |          88 |
| InnoDB System |   1769472 | 1420659 |   108 |            2 |         4 |        1768 |
| mysql         |    950272 |  527549 |    58 |            7 |         9 |       10671 |
| drone         |    294912 |   78705 |    18 |            3 |         8 |          78 |
| sys           |     16384 |     338 |     1 |            0 |         1 |           6 |
+---------------+-----------+---------+-------+--------------+-----------+-------------+
5 rows in set (0.03 sec)
```
17、每个连接分配多少内存？ 利用session表和memory_by_thread_by_current_bytes分配表进行关联查询。
```sql
select b.user, current_count_used, current_allocated, current_avg_alloc, current_max_alloc, total_allocated,current_statement from sys.x$memory_by_thread_by_current_bytes a, sys.x$session b where a.thread_id = b.thd_id;
+--------------------+--------------------+-------------------+-------------------+-------------------+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| user               | current_count_used | current_allocated | current_avg_alloc | current_max_alloc | total_allocated | current_statement                                                                                                                                                                                                          |
+--------------------+--------------------+-------------------+-------------------+-------------------+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| root@116.30.139.76 |                  0 |                 0 |            0.0000 |                 0 |               0 | SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA                                                                                                                    |
| root@172.18.77.102 |                  0 |                 0 |            0.0000 |                 0 |               0 | select b.user, current_count_used, current_allocated, current_avg_alloc, current_max_alloc, total_allocated,current_statement from sys.x$memory_by_thread_by_current_bytes a, sys.x$session b where a.thread_id = b.thd_id |
+--------------------+--------------------+-------------------+-------------------+-------------------+-----------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
2 rows in set (0.08 sec)
```
18、MySQL自增长字段的最大值和当前已经使用到的值？
```sql
select * from sys.schema_auto_increment_columns;
+-------------------+---------------------------+-------------+-----------+------------------+-----------+-------------+---------------------+----------------+----------------------+
| table_schema      | table_name                | column_name | data_type | column_type      | is_signed | is_unsigned | max_value           | auto_increment | auto_increment_ratio |
+-------------------+---------------------------+-------------+-----------+------------------+-----------+-------------+---------------------+----------------+----------------------+
| devops_platform   | idc                       | id          | int       | int(11)          |         1 |           0 |          2147483647 |              3 |               0.0000 |
| blog              | blog_article              | id          | int       | int(10) unsigned |         0 |           1 |          4294967295 |              1 |               0.0000 |
| operator-platform | user                      | id          | bigint    | bigint(20)       |         1 |           0 | 9223372036854775807 |             15 |               0.0000 |
+-------------------+---------------------------+-------------+-----------+------------------+-----------+-------------+---------------------+----------------+----------------------+
```
19、MySQL索引使用情况统计？
```sql
select * from sys.x$schema_index_statistics;
```
20、MySQL有哪些冗余索引和无用索引？
```sql
select * from sys.schema_redundant_indexes;
select * from sys.schema_unused_indexes;
```
21、MySQL内部有多个线程在运行？ MySQL内部的线程类型及数量。
```sql
select user, count(*) from sys.x$processlist group by user;
+---------------------------------+----------+
| user                            | count(*) |
+---------------------------------+----------+
| gitea@172.17.0.1                |        1 |
| innodb/buf_dump_thread          |        1 |
| innodb/dict_stats_thread        |        1 |
| innodb/io_ibuf_thread           |        1 |
| innodb/io_log_thread            |        1 |
| innodb/io_read_thread           |        4 |
| innodb/io_write_thread          |        4 |
| innodb/page_cleaner_thread      |        1 |
| innodb/srv_error_monitor_thread |        1 |
| innodb/srv_lock_timeout_thread  |        1 |
| innodb/srv_master_thread        |        1 |
| innodb/srv_monitor_thread       |        1 |
| innodb/srv_purge_thread         |        1 |
| innodb/srv_worker_thread        |        3 |
| root@116.30.139.76              |        1 |
| root@172.18.77.102              |        1 |
| sql/compress_gtid_table         |        1 |
| sql/main                        |        1 |
| sql/signal_handler              |        1 |
| sql/thread_timer_notifier       |        1 |
+---------------------------------+----------+
20 rows in set (0.04 sec)
```
22、列出所有平均运行时(以微秒计)在最高5%以内的语句
```sql
select * from sys.`x$statement_analysis`
```
23、查询当前正在执行的sql
```sql
select * from information_schema.processlist where info is not null order by time desc;
+--------+------+---------------------+------+---------+------+-----------+----------------------------------------------------------------------------------------+
| ID     | USER | HOST                | DB   | COMMAND | TIME | STATE     | INFO                                                                                   |
+--------+------+---------------------+------+---------+------+-----------+----------------------------------------------------------------------------------------+
| 119136 | root | 172.18.77.102:50876 | NULL | Query   |    0 | executing | select * from information_schema.processlist where info is not null order by time desc |
+--------+------+---------------------+------+---------+------+-----------+----------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```
23、查询dbname下所有表的名字，注释，物理大小，数据条数
```sql
select table_name,TABLE_COMMENT,CONCAT(TRUNCATE(data_length/1024/1024/1024, 4),"GB") AS data_size,table_rows from information_schema.tables where table_schema="dbname";
```
24、查询表的所有字段和注解，并以逗号连接返回一行
```sql
select GROUP_CONCAT(COLUMN_NAME),group_concat(COLUMN_COMMENT) from information_schema.COLUMNS where table_name = "tablename" and table_schema = "dbname";
```