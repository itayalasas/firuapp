module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: 2020, // Soporte para ECMAScript 2020
    },
    extends: ["eslint:recommended", "google"],
    rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", { allowTemplateLiterals: true }],
        "max-len": ["error", { code: 120 }], // Permitir líneas hasta 120 caracteres
        "object-curly-spacing": ["error", "always"], // Espacios dentro de objetos { key: value }
        "comma-dangle": ["error", "always-multiline"], // Coma final en objetos y arrays
        "indent": ["error", 4], // Ajustar indentación a 4 espacios
        "quote-props": ["error", "consistent-as-needed"], // Corregido para evitar errores
        "operator-linebreak": ["error", "after"], // Operadores como "?" y ":" deben ir al final de la línea anterior
        "eol-last": ["error", "always"], // Asegura una nueva línea al final del archivo
    },
};
