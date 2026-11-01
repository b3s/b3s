import js from "@eslint/js";
import globals from "globals";
import eslintConfigPrettier from "eslint-config-prettier";
import eslintReact from "@eslint-react/eslint-plugin";
import reactHooks from "eslint-plugin-react-hooks";
import tseslint from "typescript-eslint";

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  eslintReact.configs["recommended-type-checked"],
  eslintConfigPrettier,
  {
    plugins: {
      'react-hooks': reactHooks,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
    },
  },
  eslintReact.configs["disable-conflict-eslint-plugin-react-hooks"],
  {
    rules: {
      "@eslint-react/dom-no-unknown-property": "error",
      "@eslint-react/dom-no-unsafe-target-blank": "error",
      "@eslint-react/globals": "error",
      "@eslint-react/immutability": "error",
      "@eslint-react/no-duplicate-key": "error",
      "@eslint-react/no-missing-component-display-name": "error",
      "@eslint-react/purity": "error",
      "@eslint-react/refs": "error",
      "@eslint-react/set-state-in-effect": "error",
    },
  },
  {
    languageOptions: {
      globals: { ...globals.browser },
      ecmaVersion: "latest",
      sourceType: "module",
      parserOptions: {
        project: true
      }
    },
    rules: {
      "linebreak-style": ["error", "unix"],
      quotes: ["error", "double", { avoidEscape: true }],
      semi: ["error", "always"]
    }
  }
];
