// ESLint 9 flat config. Replaces the legacy .eslintrc removed in the eslint 9
// bump (which had left `npm run lint` broken). Lints backend/src TypeScript with
// eslint:recommended + typescript-eslint recommended, with prettier turned off
// so formatting is left to prettier. Not type-aware (no parserOptions.project),
// to keep it fast and avoid tsconfig coupling — add `project` later if we want
// type-checked rules.
import js from '@eslint/js';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import prettier from 'eslint-config-prettier';
import globals from 'globals';

export default [
  { ignores: ['dist/**', 'node_modules/**', 'coverage/**'] },
  js.configs.recommended,
  {
    files: ['**/*.ts'],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaVersion: 'latest', sourceType: 'module' },
      globals: { ...globals.node },
    },
    plugins: { '@typescript-eslint': tsPlugin },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      // TS's own compiler already catches undefined references; eslint's no-undef
      // only produces false positives here on type-only globals (NodeJS) and
      // cross-context globals (window/document inside browser-eval callbacks).
      'no-undef': 'off',
      // Pre-existing debt across the codebase — surfaced as warnings so lint can
      // gate on real errors today; ratchet these to 'error' as they're cleaned up.
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
      ],
    },
  },
  prettier,
];
