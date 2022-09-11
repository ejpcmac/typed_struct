const Configuration = {
  parserPreset: './commitlint.parser-preset',
  rules: {
    'body-leading-blank': [2, 'always'],
    'body-max-line-length': [2, 'always', 80],
    'footer-leading-blank': [2, 'always'],
    'footer-max-line-length': [2, 'always', 80],
    'header-max-length': [2, 'always', 80],
    'scope-case': [2, 'always', 'snake-case'],
    'subject-case': [
      2,
      'never',
      ['sentence-case', 'start-case', 'pascal-case', 'upper-case'],
    ],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-case': [2, 'always', 'lower-case'],
    'type-empty': [2, 'never'],
    'type-enum': [
      2,
      'always',
      [
        'build',
        'chore',
        'ci',
        'deps',
        'docs',
        'feat',
        'fix',
        'perf',
        'refactor',
        'revert',
        'sec',
        'style',
        'test',
      ],
    ],
  },
};

module.exports = Configuration;
