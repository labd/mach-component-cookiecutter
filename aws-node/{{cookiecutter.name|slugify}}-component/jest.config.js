module.exports = {
  // coverageReporters: ['text', 'cobertura', 'lcov'],
  collectCoverageFrom: ['./src/lib/**/*.ts'],
  setupFilesAfterEnv: ['./jest.setup.js'],
  moduleDirectories: ['./node_modules', './'],
  moduleFileExtensions: ['ts', 'tsx', 'js'],
  moduleNameMapper: {},
  // reporters: ['default', 'jest-junit'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest',
  },
  testMatch: ['<rootDir>/**/tests/**/*.test.{ts,tsx,js}'],
  modulePathIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/dist'],
}
