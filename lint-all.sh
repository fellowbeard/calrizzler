#!/bin/bash

# Lint all script - runs both frontend and backend linters

set -e  # Exit on first error

echo "╭─────────────────────────────────────╮"
echo "│  Starting Linting Process           │"
echo "╰─────────────────────────────────────╯"
echo ""

# Frontend linting
echo "┌─ Frontend Linting (ESLint) ─────────┐"
cd calrizzler-frontend
if npm run lint; then
    echo "✓ Frontend: No issues found"
else
    echo "✗ Frontend: Issues found (run 'npm run lint:fix' to auto-fix)"
    cd ..
    exit 1
fi
cd ..
echo ""

# Backend linting
echo "┌─ Backend Linting (Rubocop) ─────────┐"
if bundle exec rubocop; then
    echo "✓ Backend: No issues found"
else
    echo "✗ Backend: Issues found (run 'bundle exec rubocop -A' to auto-fix)"
    exit 1
fi

echo ""
echo "╭─────────────────────────────────────╮"
echo "│  ✓ All linting checks passed!      │"
echo "╰─────────────────────────────────────╯"
