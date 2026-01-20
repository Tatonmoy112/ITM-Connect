#!/bin/bash

# Flutter Setup Script for ITM Connect
# This script installs Flutter via snap and sets up the project.

echo "🚀 Starting Flutter Setup..."

# Check if snap is installed
if ! command -v snap &> /dev/null; then
    echo "❌ Error: 'snap' is not installed. Please install snapd first: sudo apt update && sudo apt install snapd"
    exit 1
fi

echo "📦 Installing Flutter via Snap (classic)..."
echo "Please enter your password if prompted."
sudo snap install flutter --classic

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Flutter. Please try running 'sudo snap install flutter --classic' manually."
    exit 1
fi

echo "⚙️ Initializing Flutter SDK..."
flutter sdk-path

echo "📥 Fetching project dependencies..."
flutter pub get

echo "✅ Setup complete!"
echo "You can now run the project using: flutter run -d chrome"
echo "Note: If 'flutter' command is still not found in this terminal, try opening a new terminal window or run 'source ~/.bashrc'."
