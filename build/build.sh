#!/bin/bash
npm install
npm run build

# Optional: copy contents to build folder if needed
mkdir -p build
cp -r ./build/* ./build/
             