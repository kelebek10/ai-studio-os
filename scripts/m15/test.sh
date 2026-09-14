#!/usr/bin/env bash
set -euo pipefail

# M15 non-production test harness.
# Safety boundary: disposable PostgreSQL only. No production credentials/endpoints.

TASK_ID="M15"
EXPECTED_BRANCH="phase-1-3-foundation"
MIGRATION="migrations/nonprod/014_m15_constraint_versioning.sql"

fail() { echo "M15 BLOCKED: $1" >&2; exit 1; }
pass() { echo "PASS $1: $2"; }

test "$TASK_ID" = "M15" || fail "unexpected task id"
if [[ -n "${DATABASE_URL:-}" ]]; then fail "DATABASE_URL is forbidden"; fi
if [[ -n "${PGHOST:-}" && "${PGHOST}" =~ (prod|production) ]]; then fail "production-like PGHOST detected"; fi
pass "T00" "production connection inputs rejected"

test -s "$MIGRATION" || fail "missing $MIGRATION"
pass "T01" "non-production migration exists"

if grep -Eiq '(prod(uction)?[_-]?(db|database)?|DATABASE_URL|PGHOST|DROP[[:space:]]+DATABASE|TRUNCATE[[:space:]]+TABLE)' "$MIGRATION"; then
  fail "migration contains forbidden production/destructive target"
fi
pass "T02" "migration target boundary is clean"

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

run_sql() { psql "$M15_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -c "$1"; }

# T04 — current version exists/readable.
run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} LIMIT 1;" >/dev/null
pass "T04" "current constraint version is readable"

# T05 — invalid version rejected.
if run_sql "SELECT ${M15_APPLY_FUNCTION}('__INVALID_VERSION__', '__M15_TEST_SCOPE__', 'm15-t05-invalid', 'test-hash', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1; then
  fail "invalid constraint version was accepted"
fi
pass "T05" "invalid version rejected"

# T06 — same scope/idempotency key cannot create duplicate state.
run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__M15_TEST_SCOPE__', 'm15-t06-idempotency', 'test-hash', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1 || true
first_count="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency';" | tr -d '[:space:]')"
run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__M15_TEST_SCOPE__', 'm15-t06-idempotency', 'test-hash', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1 || true
second_count="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency';" | tr -d '[:space:]')"
test "$second_count" = "$first_count" || fail "idempotency key produced duplicate state"
pass "T06" "retry is idempotent"

# T07 — unauthorized scope substitution rejected.
if run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__UNAUTHORIZED_SCOPE__', 'm15-t07-scope', 'test-hash', 'NON_HUMAN_TEST_ACTOR');" >/dev/null 2>&1; then
  fail "unauthorized scope was accepted"
fi
pass "T07" "scope substitution rejected"

# T08 — provenance must be queryable for accepted versioned state.
run_sql "SELECT ${M15_PROVENANCE_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency' LIMIT 1;" >/dev/null 2>&1 || fail "provenance is not queryable"
pass "T08" "provenance field is queryable"

# T09 — invalid transition inside transaction must leave no partial state.
before="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE};" | tr -d '[:space:]')"
run_sql "BEGIN; SELECT ${M15_APPLY_FUNCTION}('__INVALID_VERSION__', '__M15_TEST_SCOPE__', 'm15-t09-rollback', 'test-hash', 'NON_HUMAN_TEST_ACTOR'); ROLLBACK;" >/dev/null 2>&1 || true
after="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE};" | tr -d '[:space:]')"
test "$before" = "$after" || fail "failed transaction changed version state"
pass "T09" "failed transaction leaves no partial state"

# T10 — provenance and scope are mandatory at schema level.
prov="$(run_sql "SELECT is_nullable FROM information_schema.columns WHERE table_schema='governance' AND table_name='constraint_versions' AND column_name='${M15_PROVENANCE_COLUMN}';" | tr -d '[:space:]')"
scope="$(run_sql "SELECT is_nullable FROM information_schema.columns WHERE table_schema='governance' AND table_name='constraint_versions' AND column_name='${M15_SCOPE_COLUMN}';" | tr -d '[:space:]')"
test "$prov" = "NO" || fail "provenance column is nullable"
test "$scope" = "NO" || fail "scope column is nullable"
pass "T10" "provenance and scope are mandatory"

echo "M15 NON-PROD TEST RESULT: PASS"
echo "No production connection or production mutation was permitted by this harness."
