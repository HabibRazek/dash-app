# Use the official Bun image
# See available versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base

# Set the working directory inside the container
WORKDIR /usr/src/app

# Install dependencies into a temp directory for caching purposes
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

# Copy dev dependencies for later use (test, build, etc.)
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# Copy project files
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# Optional: Run tests and build the app for production
ENV NODE_ENV=production
RUN bun test
RUN bun run build

# Create the final production image
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/.next .next
COPY --from=prerelease /usr/src/app/public ./public
COPY --from=prerelease /usr/src/app/package.json ./

# Expose port 3000 and start the Next.js app
USER bun
EXPOSE 3000/tcp
CMD ["bun", "run", "start"]
