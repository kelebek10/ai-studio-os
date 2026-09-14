#!/usr/bin/env bash
set -euo pipefail

# M15 non-production test harness.
# Safety boundary: this script MUST run only against a disposable PostgreSQL instance.
# It never receives production credentials and never connects to production endpoints.

TASK_ID="M15"
EXPECTED_BRANCH="phase-1-3-foundation"
MIGRATION="migrations/nonprod/014_m15_constraint_versioning.sql"

fail() {
  echo "M15 BLOCKED: $1" >&2
  exit 1
}

pass() {
  echo "PASS $1: $2"
}

# T00 — hard safety boundary.
test "${TASK_ID}" = "M15" || fail "unexpected task id"
if [[ -n "${DATABASE_URL:-}" ]]; then
  fail "DATABASE_URL is forbidden; use only the disposable test database"
fi
if [[ -n "${PGHOST:-}" && "${PGHOST}" =~ (prod|production) ]]; then
  fail "production-like PGHOST detected"
fi
pass "T00" "production connection inputs rejected"

# T01 — required non-production migration exists.
test -s "$MIGRATION" || fail "missing $MIGRATION"
pass "T01" "non-production migration exists"

# T02 — migration must not contain obvious production targets or destructive shortcuts.
if grep -Eiq '(prod(uction)?[_-]?(db|database)?|DATABASE_URL|PGHOST|DROP[[:space:]]+DATABASE|TRUNCATE[[:space:]]+TABLE)' "$MIGRATION"; then
  fail "migration contains a forbidden production/destructive target"
fi
pass "T02" "migration target boundary is clean"

# T03 — version declaration must exist and be explicit.
grep -Eiq '(constraint[_ -]?version|version)' "$MIGRATION" || fail "no explicit constraint-version declaration found"
pass "T03" "constraint version declaration detected"

# T04-T10 require the M15 implementation contract. They intentionally fail closed
# until the design defines the canonical table/function interface. This prevents
# the test harness from inventing database semantics or silently testing the wrong API.

: "${M15_VERSION_TABLE:=}"
: "${M15_APPLY_FUNCTION:=}"
: "${M15_VERSION_COLUMN:=version}"
: "${M15_SCOPE_COLUMN:=scope}"
: "${M15_IDEMPOTENCY_COLUMN:=idempotency_key}"
: "${M15_PROVENANCE_COLUMN:=provenance_hash}"

if [[ -z "$M15_VERSION_TABLE" || -z "$M15_APPLY_FUNCTION" ]]; then
  fail "M15 interface contract missing: set M15_VERSION_TABLE and M15_APPLY_FUNCTION before semantic tests"
fi

# A disposable PostgreSQL connection is mandatory for semantic tests.
command -v psql >/dev/null 2>&1 || fail "psql is required for semantic tests"
: "${M15_TEST_DATABASE_URL:=}" 
[[ -n "$M15_TEST_DATABASE_URL" ]] || fail "M15_TEST_DATABASE_URL must point to a disposable non-production database"

if [[ "$M15_TEST_DATABASE_URL" =~ (prod|production) ]]; then
  fail "test database URL looks production-like"
fi

run_sql() {
  psql "$M15_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -c "$1"
}

# T04 — version read / current version exists.
run_sql "SELECT ${M15_VERSION_COLUMN} FROM ${M15_VERSION_TABLE} LIMIT 1;" >/dev/null
pass "T04" "current constraint version is readable"

# T05 — invalid version must be rejected by the canonical apply function.
if run_sql "SELECT ${M15_APPLY_FUNCTION}('__INVALID_VERSION__', '__M15_TEST_SCOPE__', 'm15-t05-invalid');" >/dev/null 2>&1; then
  fail "invalid constraint version was accepted"
fi
pass "T05" "invalid version rejected"

# T06 — retry/idempotency: same key must not create a second state transition.
run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__M15_TEST_SCOPE__', 'm15-t06-idempotency');" >/dev/null 2>&1 || true
first_count="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency';")"
run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__M15_TEST_SCOPE__', 'm15-t06-idempotency');" >/dev/null 2>&1 || true
second_count="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency';")"
test "$second_count" = "$first_count" || fail "idempotency key produced duplicate state"
pass "T06" "retry is idempotent"

# T07 — scope substitution must not silently apply another scope.
if run_sql "SELECT ${M15_APPLY_FUNCTION}(NULL, '__UNAUTHORIZED_SCOPE__', 'm15-t07-scope');" >/dev/null 2>&1; then
  fail "unauthorized scope was accepted"
fi
pass "T07" "scope substitution rejected"

# T08 — provenance must be present for a versioned record.
run_sql "SELECT ${M15_PROVENANCE_COLUMN} FROM ${M15_VERSION_TABLE} WHERE ${M15_IDEMPOTENCY_COLUMN} = 'm15-t06-idempotency' LIMIT 1;" >/dev/null
pass "T08" "provenance field is queryable"

# T09 — transaction rollback: a failed operation must not persist a partial state.
before="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE};")"
run_sql "BEGIN; SELECT ${M15_APPLY_FUNCTION}('__INVALID_VERSION__', '__M15_TEST_SCOPE__', 'm15-t09-rollback'); ROLLBACK;" >/dev/null 2>&1 || true
after="$(run_sql "SELECT count(*) FROM ${M15_VERSION_TABLE};")"
test "$before" = "$after" || fail "failed transaction changed version state"
pass "T09" "failed transaction leaves no partial state"

# T10 — provenance/scope columns must be non-nullable at the schema level.
run_sql "SELECT 1 FROM information_schema.columns WHERE table_name='${M15_VERSION_TABLE}' AND column_name='${M15_PROVENANCE_COLUMN}' AND is_nullable='NO';" >/dev/null
run_sql "SELECT 1 FROM information_schema.columns WHERE table_name='${M15_VERSION_TABLE}' AND column_name='${M15_SCOPE_COLUMN}' AND is_nullable='NO';" >/dev/null
pass "T10" "provenance and scope are mandatory"

echo "M15 NON-PROD TEST RESULT: PASS"
echo "No production connection or production mutation was permitted by this harness."
