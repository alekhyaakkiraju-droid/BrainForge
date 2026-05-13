module.exports = {
  root: true,
  env: {
    es2019: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
    tsconfigRootDir: __dirname,
  },
  ignorePatterns: [
    "/lib/**/*",
    ".eslintrc.js",
  ],
  plugins: [
    "@typescript-eslint",
  ],
  rules: {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "no-console": ["warn", { allow: ["warn", "error", "info"] }],
    "quotes": ["error", "double"],
    "semi": ["error", "always"],
    "indent": ["error", 2],
    "max-len": ["warn", { code: 120 }],
  },
};
