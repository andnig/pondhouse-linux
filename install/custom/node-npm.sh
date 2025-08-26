#!/bin/bash

set -e # Exit on error

echo "Installing Node 22 via mise..."

mise install node@22

# Set Node 22 as global default
mise global node@22

# Verify installation
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

echo "Installing global npm packages..."
mkdir -p ~/.npm-global/lib
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH

# Install eslint
echo "Installing eslint..."
npm install -g eslint

# Install TypeScript Language Server
echo "Installing typescript-language-server..."
npm install -g typescript-language-server

# Install TypeScript
echo "Installing typescript..."
npm install -g typescript

# Install ts-node
echo "Installing ts-node..."
npm install -g ts-node

# Install pnpm
echo "Installing pnpm..."
npm install -g pnpm

echo "Installation complete!"
echo "Installed packages:"
npm list -g --depth=0
