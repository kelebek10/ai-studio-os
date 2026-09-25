#!/usr/bin/env bash
set -euo pipefail
DB="docker exec paiforge-m19-postgres psql -U postgres -d paiforge_m19 -At"

echo "M19.4 T01 schema: $($DB -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='m19_control' AND table_name IN ('task_assignment','task_lease');")"
echo "M19.4 T09 lease index: $($DB -c "SELECT count(*) FROM pg_indexes WHERE schemaname='m19_control' AND indexname='task_one_active_lease';")"
echo "M19.4 functions: $($DB -c "SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='m19_control' AND p.proname IN ('dispatch_task','ack_task','create_lease');")"
echo "M19.4 role execute: $($DB -c "SELECT count(*) FROM information_schema.role_routine_grants WHERE grantee='m19_app' AND routine_schema='m19_control' AND privilege_type='EXECUTE' AND routine_name IN ('dispatch_task','ack_task','create_lease');")"
