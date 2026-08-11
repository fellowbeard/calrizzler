#!/bin/bash

# Auto-fix linting issues in both frontend and backend

set -e

echo "╭──────────────────────────────────────╮"
echo "│  Starting Auto-Fix Linting           │"
echo "╰──────────────────────────────────────╯"
echo ""

# Frontend auto-fix
echo "┌─ Frontend Auto-Fix (ESLint) ────────┐"
cd calrizzler-frontend
npm run lint:fix
echo "✓ Frontend issues auto-fixed"
cd ..
echo ""

# Backend auto-fix
echo "┌─ Backend Auto-Fix (Rubocop) ────────┐"
bundle exec rubocop -A
echo "✓ Backend issues auto-fixed"

echo ""
echo "╭──────────────────────────────────────╮"
echo "│  ✓ Auto-fix completed!              │"
echo "│    Review changes and commit        │"
echo "╰──────────────────────────────────────╯"
