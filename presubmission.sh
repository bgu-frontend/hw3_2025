#!/bin/bash
# Kill ports if busy
if [ -z "$1" ]; then
  echo "Usage: $0 <git_repo_url> <path_to_env_file>" 
  exit 1
fi

REPO_URL="$1"
TIMESTAMP=$(date +"%m_%d_%y__%H_%M_%S")
TMP_DIR="./presubmission_tests/$TIMESTAMP"
echo "Using temp dir: $TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

git clone "$REPO_URL" repo
if [ $? -ne 0 ]; then
  echo "Git clone failed."
  exit 1
fi

cd repo || exit 1
git checkout submission_hw3
cp "$2" ./backend/.env || { echo "Failed to copy .env file"; exit 1; }

# Define the expected structure
expected_paths=(
  "./frontend"
  "./frontend/playwright-tests/test.spec.ts"
  "./frontend/playwright.config.ts"
  "./frontend/package.json"
  "./frontend/src/components"
  "./frontend/src/contexts"
  "./backend"
  "./backend/config"
  "./backend/controllers"
  "./backend/services"
  "./backend/routes"
  "./backend/middlewares"
  "./backend/models"
  "./backend/tests/crud.test.ts"
  "./backend/package.json"
)

echo "Checking folder structure..."
all_exist=true

for path in "${expected_paths[@]}"; do
  if [ ! -e "$path" ]; then
    echo "Missing: $path"
    all_exist=false
  else
    echo "Found: $path"
  fi
done

if [ "$all_exist" = false ]; then
  echo "Some files or folders are missing."
  exit 1
fi

# Install frontend dependencies
cd frontend || exit 1
npm install || { echo "frontend: npm install failed"; exit 1; }
npx playwright install || { echo "Playwright install failed"; exit 1; }

# Install backend dependencies
cd ../backend || exit 1
npm install || { echo "backend: npm install failed"; exit 1; }

PORTS=(3000 3001)
for PORT in "${PORTS[@]}"; do
  echo "Checking port $PORT..."
  PIDS=$(lsof -ti tcp:$PORT)
  if [ -n "$PIDS" ]; then
    echo "Found processes on port $PORT: $PIDS"
    for PID in $PIDS; do
      echo "Killing process $PID on port $PORT"
      kill -9 "$PID" || echo "Failed to kill process $PID"
    done
  else
    echo "No process found on port $PORT"
  fi
done



# Run backend tests
cd ../backend || exit 1
echo "Running backend tests..."
npm run test || echo "Backend tests failed."

# Start backend
npm run dev > ../backend.log 2>&1 &
BACK_PID=$!
echo "Started backend (PID $BACK_PID)"
sleep 1

# Start frontend
cd ../frontend || exit 1
npm run dev > ../frontend.log 2>&1 &
FRONT_PID=$!
echo "Started frontend (PID $FRONT_PID)"
sleep 1

# Run frontend tests
cd ../frontend || exit 1
echo "Running frontend (Playwright) tests..."
npm run test || echo "Frontend tests failed."

# Cleanup
echo "Killing servers..."
kill -9 $BACK_PID $FRONT_PID 2>/dev/null || echo "Failed to kill one or more servers"

echo "Presubmission check completed."
