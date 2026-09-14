#!/usr/bin/env bash
set -euo pipefail

TASK_ID="M15"
EXPECTED_BRANCH="phase-1-3-foundation"
MIGRATION="migrations/nonprod/014_m15_constraint_versioning.sql"
SCOPE="M15_TEST"
PROVENANCE="0123456789abcdef0123456789abcdef"

fail(){ echo "M15 BLOCKED: $1" >&2; exit 1; }
pass(){ echo "PASS $1: $2"; }

test "$TASK_ID" = "M15" || fail "unexpected task id"
[[ -z "${DATABASE_URL:-}" ]] || fail "DATABASE_URL is forbidden"
if [[ -n "${PGHOST:-}" && "${PGHOST}" =~ (prod|production) ]]; then fail "production-like PGHOST detected"; fi
pass "T00" "production connection inputs rejected"

test -s "$MIGRATION" || fail "missing $MIGRATION"
pass "T01" "non-production migration exists"

if grep -Eiq 'DROP[[:space:]]+DATABASE|TRUNCATE[[:space:]]+TABLE' "$MIGRATION"; then fail "destructive SQL detected"; fi
pass "T02" "destructive target boundary is clean"

grep -Eiq 'constraint[_ -]?version' "$MIGRATION" || fail "no explicit constraint-version declaration"
pass "T03" "constraint version declaration detected"

: "${M15_VERSION_TABLE:=governance.constraint_versions}"
: "${M15_APPLY_FUNCTION:=governance.apply_constraint_version}"
: "${M15_VERSION_COLUMN:=version}"
: "${M15_SCOPE_COLUMN:=scope}"
: "${M15_IDEMPOTENCY_COLUMN:=idempotency_key}"
: "${M15_PROVENANCE_COLUMN:=provenance_hash}"
: "${M15_STATUS_COLUMN:=status}"

command -v psql >/dev/null 2>&1 || fail "psql is required"
: "${M15_TEST_DATABASE_URL:=}"
[[ -n "$M15_TEST_DATABASE_URL" ]] || fail "M15_TEST_DATABASE_URL is required"
if [[ "$M15_TEST_DATABASE_URL" =~ (prod|production) ]]; then fail "test database URL looks production-like"; fi

run_sql(){ psql "$M15_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -c "$1"; }
run_sql "SET paz.m15_nonprod='true'; SET paz.environment='test'; SELECT 1;" >/dev/null

run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_VERSION_COLUMN}='v1' AND ${M15_STATUS_COLUMN}='ACTIVE';" | grep -q v1 || fail "T04 current v1 is not readable"
pass "T04" "current v1 is readable"

if run_sql "SELECT ${M15_APPLY_FUNCTION}('__INVALID_VERSION__', '$SCOPE', 'm15-t05-invalid', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1; then fail "T05 invalid version was accepted"; fi
pass "T05" "invalid version rejected"

R1="$(run_sql "SELECT ${M15_APPLY_FUNCTION}('v1', '$SCOPE', 'm15-t06-retry', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');")"
R2="$(run_sql "SELECT ${M15_APPLY_FUNCTION}('v1', '$SCOPE', 'm15-t06-retry', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');")"
[[ "$R1" == "$R2" ]] || fail "T06 retry result mismatch"
COUNT="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN}='m15-t06-retry';" | tr -d '[:space:]')"
[[ "$COUNT" == "1" ]] || fail "T06 duplicate state created"
pass "T06" "retry is deterministic and idempotent"

if run_sql "SELECT ${M15_APPLY_FUNCTION}('v1', 'UNAUTHORIZED_SCOPE', 'm15-t07-scope', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1; then fail "T07 unauthorized scope was accepted"; fi
pass "T07" "scope substitution rejected"

run_sql "SELECT ${M15_PROVENANCE_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN}='m15-t06-retry';" | grep -q "$PROVENANCE" || fail "T08 provenance missing"
pass "T08" "provenance is queryable"

run_sql "SELECT ${M15_APPLY_FUNCTION}('v2', '$SCOPE', 'm15-t09-forward', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');" >/dev/null
ACTIVE="$(run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_SCOPE_COLUMN}='$SCOPE' AND ${M15_STATUS_COLUMN}='ACTIVE' ORDER BY created_at DESC, transition_id DESC LIMIT 1;" | tr -d '[:space:]')"
[[ "$ACTIVE" == "v2" ]] || fail "T09 v1->v2 transition failed"

if run_sql "SELECT ${M15_APPLY_FUNCTION}('v9', '$SCOPE', 'm15-t09-invalid', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1; then fail "T09 unsupported transition accepted"; fi
ACTIVE2="$(run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_SCOPE_COLUMN}='$SCOPE' AND ${M15_STATUS_COLUMN}='ACTIVE' ORDER BY created_at DESC, transition_id DESC LIMIT 1;" | tr -d '[:space:]')"
[[ "$ACTIVE2" == "v2" ]] || fail "T09 failed transition changed active state"

run_sql "SELECT ${M15_APPLY_FUNCTION}('v1', '$SCOPE', 'm15-t09-rollback', '$PROVENANCE', 'NON_HUMAN_TEST_ACTOR');" >/dev/null
ACTIVE3="$(run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_SCOPE_COLUMN}='$SCOPE' AND ${M15_STATUS_COLUMN}='ACTIVE' ORDER BY created_at DESC, transition_id DESC LIMIT 1;" | tr -d '[:space:]')"
[[ "$ACTIVE3" == "v1" ]] || fail "T09 explicit rollback failed"
HISTORY="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_SCOPE_COLUMN}='$SCOPE' AND ${M15_VERSION_COLUMN} IN ('v1','v2');" | tr -d '[:space:]')"
[[ "$HISTORY" -ge 3 ]] || fail "T09 transition history was not preserved"
pass "T09" "forward transition, failed transition, and explicit rollback verified"

for c in version scope idempotency_key provenance_hash created_at created_by status; do
  n="$(run_sql "SELECT is_nullable FROM information_schema.columns WHERE table_schema='governance' AND table_name='constraint_versions' AND column_name='$c';" | tr -d '[:space:]')"
  [[ "$n" == "NO" ]] || fail "T10 column $c is nullable or missing"
done
pass "T10" "required schema fields are NOT NULL"

echo "M15 NON-PROD TEST RESULT: PASS"
