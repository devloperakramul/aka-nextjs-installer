#!/bin/bash
# One-click pnpm Next.js + Prisma project setup with prompts for project folder and DB name

# Display the current folder
echo "=== Starting the Next.js + Prisma setup process ==="
echo "Current folder: $(pwd)"


# Step 1: Prompt for project folder name (default to current folder './')
read -p "Enter project folder name (default is './'): " projectFolder
if [ -z "$projectFolder" ]; then
    projectFolder="./"
fi
echo "Project folder set to: $projectFolder"

# Step 2: Set default DB name based on project folder name (default is 'mydb' if folder is './')
if [ "$projectFolder" == "./" ]; then
    defaultDbName="mydb"
else
    defaultDbName=$(basename "$projectFolder")
fi
echo "Default database name set to: $defaultDbName"

# Step 3: Set the database name
dbName=$defaultDbName
echo "Database name set to: $dbName"

# Step 4: Create Next.js app in the specified folder, with flags to suppress prompts
flags="--ts --tailwind --eslint --app --src-dir --import-alias \"@/*\" --use-pnpm"

echo "Creating Next.js app with the following configuration: TypeScript, Tailwind CSS, ESLint, and pnpm"

if [ "$projectFolder" != "./" ]; then
    echo "Creating Next.js app in $projectFolder..."
    pnpm dlx create-next-app@latest "$projectFolder" $flags
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create Next.js app. Exiting..."
        exit 1
    fi
    cd "$projectFolder"
else
    echo "Creating Next.js app in the current directory..."
    pnpm dlx create-next-app@latest ./ $flags
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create Next.js app. Exiting..."
        exit 1
    fi
fi
echo "Next.js app created successfully."

# Step 5: Install Prisma client and dev dependencies
echo "Installing Prisma client and development dependencies..."
pnpm install
pnpm add @prisma/client
pnpm add -D prisma
echo "Prisma dependencies installed."

# Step 5.1: Install Autoprefixer and ensure it's configured with PostCSS
echo "Installing Autoprefixer..."
pnpm install -D autoprefixer
echo "Autoprefixer installed."

# Step 5.2: Ensure PostCSS config includes Autoprefixer
echo "Configuring PostCSS to include Autoprefixer..."
cat <<EOL > postcss.config.js
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOL
echo "PostCSS configured with Autoprefixer."

# Step 6: Initialize Prisma
echo "Initializing Prisma..."
pnpm dlx prisma init
echo "Prisma initialized."

# Step 7: Set up the .env file with the prompted DB name
echo "Setting up .env file for the database..."
echo "DATABASE_URL=\"postgresql://postgres:admin@localhost:5432/$dbName?schema=public\"" > .env
echo ".env file created with DATABASE_URL."

# Step 8: Create lib/prisma.js and lib/prisma.ts in src folder for cleaner structure
echo "Creating Prisma files in src/lib..."
mkdir -p src/lib
cat <<EOL > src/lib/prisma.js
//lib/prisma.js

import { PrismaClient } from '@prisma/client';

const globalForPrisma = global;

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: ['query'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

EOL

cat <<EOL > src/lib/prisma.ts
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = global as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma || new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma

export default prisma

EOL
echo "Prisma setup in src/lib completed."

# Step 9: Ask if the user has a Prisma model ready
read -p "Do you have a Prisma model ready? (y/no): " hasModel

if [ "$hasModel" == "y" ]; then
    # Create a temp file to store the model
    tempFile="temp_model.txt"
    touch "$tempFile"

    # Open the temp file in the default editor (you can change this to your preferred editor)
    echo "Opening $tempFile for you to paste your model..."
    ${EDITOR:-nano} "$tempFile" # Opens with nano or your default editor if set

    # Wait for user to confirm that they have finished editing the model
    read -p "Is your model input complete? (y to proceed): " modelComplete

    if [ "$modelComplete" == "y" ]; then
        # Append the custom model from the temp file to schema.prisma
        echo "Adding your model to schema.prisma..."
        cat "$tempFile" >> prisma/schema.prisma
        echo "Model added to schema.prisma."

        # Delete the temporary file
        rm "$tempFile"
        echo "Temporary model file deleted."

    else
        echo "Model input not complete. Exiting..."
        exit 1
    fi
else
    # Proceed with the default User model if user does not have a model ready
    echo "No custom model provided. Using default User model..."
    cat <<EOL >> prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
generator client {
  provider = "prisma-client-js"
}
model User {
  id        Int      @id @default(autoincrement())
  name      String
  email     String   @unique
  createdAt DateTime @default(now())
}
EOL
    echo "Default User model added to schema.prisma."
fi

# Step 10: Run Prisma migration
echo "Running Prisma migration to create database tables..."
pnpm dlx prisma migrate dev --name init
echo "Prisma migration completed."

# Step 11: Generate the Prisma client
echo "Generating the Prisma client..."
pnpm dlx prisma generate
echo "Prisma client generated."

# Step 12: Clean up and update src/app/globals.css and src/app/page.tsx with specific content
echo "Updating src/app/globals.css and src/app/page.tsx with custom content..."

# Write content to src/app/globals.css
cat <<EOL > src/app/globals.css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* div,
p {
  border: solid;
} */
EOL

# Write content to src/app/page.tsx
cat <<EOL > src/app/page.tsx
export default function Home() {
  return (
    <>
      <h1> this is new aka project</h1>
    </>
  );
}
EOL
echo "globals.css and page.tsx updated."

# Step 13: Initialize Git, add all files, and commit with the message "aka-init"
echo "Initializing Git repository..."
git init
git add .
git commit -m "aka-init"
echo "Git repository initialized and first commit created."

# Step 14: Open VSCode in the project folder
echo "Opening the project in VSCode..."
code .

# Step 15: Start Prisma Studio
echo "Starting Prisma Studio..."
echo pnpm dlx prisma studio &
echo "Prisma Studio started."

# Step 16: Run the development server
echo "Starting the development server..."
pnpm run dev

echo "=== Project setup completed successfully! ==="

read -p ""
