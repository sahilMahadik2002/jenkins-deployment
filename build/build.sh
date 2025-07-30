#!/bin/bash
npm install
npm run build

# Optional: copy dist output to build folder
mkdir -p build
cp -r ./dist/* ./build/
