#!/usr/bin/env bash
# Validation: ejercita el DatabaseService y ViewModel con SQLite real
set -e
cd "$(dirname "$0")/.."

echo "🔨 Building..."
swift build -q

echo ""

# Validación directa vía SQLite
DB="$HOME/.local/share/opencode/opencode.db"
echo ""
echo "📊 Validación SQLite directa:"
echo "   DB: $DB"
if [ -f "$DB" ]; then
    for label in "5h:18000" "7d:604800" "30d:2592000"; do
        name="${label%%:*}"
        secs="${label##*:}"
        cost=$(sqlite3 "$DB" "SELECT COALESCE(ROUND(SUM(cost),2), 0) FROM session WHERE time_created > (strftime('%s','now') - $secs) * 1000")
        echo "   $name: \$$cost"
    done
    all_time=$(sqlite3 "$DB" "SELECT COALESCE(ROUND(SUM(cost),2), 0) FROM session")
    sessions=$(sqlite3 "$DB" "SELECT COUNT(*) FROM session")
    echo "   Total histórico: \$$all_time ($sessions sesiones)"
else
    echo "   ⚠️  No hay base de datos todavía. Usá opencode primero."
fi
echo ""
echo "✅ Validación completa."
