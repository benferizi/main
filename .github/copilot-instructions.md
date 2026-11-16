# Copilot instructions

## Project overview

- This repository is a small Node.js web app using Express. The application entry point is `server.js`.
- The app listens on port 3000 and serves `Hello remote world!` at `/`.
- Use the existing CommonJS and Express patterns when changing application code.

## Development and validation

- Run the app with `npm start`.
- The GitHub Actions workflow (`.github/workflows/webpack.yml`) installs dependencies with `npm install` and runs `npx webpack`.
- There is currently no test or lint script in `package.json`. Do not assume a test framework is present; validate behavior appropriate to the change.

## Code style

- Follow the repository's ESLint configuration in `.eslintrc.json` and match the style of nearby code.
- Keep changes focused and avoid adding dependencies unless they are necessary.
