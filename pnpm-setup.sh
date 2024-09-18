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

# Step 3: Prompt for database name, default is project folder name if given, else 'mydb'
#read -p "Enter database name (default is '$defaultDbName'): " dbName
#if [ -z "$dbName" ]; then
    dbName=$defaultDbName
#fi
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

# Step 9: Create a sample model in schema.prisma
echo "Adding a sample User model to prisma/schema.prisma..."
cat <<EOL > prisma/schema.prisma
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
echo "Sample User model added to schema.prisma."

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
echo pnpm run dev

echo "=== Project setup completed successfully! ==="
 
 read -p ""