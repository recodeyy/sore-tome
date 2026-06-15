module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js', '**/__tests__/**/*.test.ts'],
  verbose: true,
  forceExit: true,
  // NOTE: resetMocks/restoreMocks would wipe jest.mock() factory implementations.
  // Use clearMocks only to clear call history, not implementations.
  clearMocks: true,
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  moduleNameMapper: {
    '^(\\.\\.\\/|\\.\\/)(.+)\\.js$': '$1$2',
  },
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: 'tsconfig.json',
      diagnostics: { ignoreCodes: [151002] },
    }],
  },
};
