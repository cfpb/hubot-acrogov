# hubot-acrogov [![Build Status][travis-image]][travis-url] [![NPM version][npm-image]][npm-url]

A hubot script that defines acronyms used by government agencies

See [`src/acrogov.coffee`](src/acrogov.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-acrogov --save`

Then add **hubot-acrogov** to your `external-scripts.json`:

```json
["hubot-acrogov"]
```

## Sample Interaction

```
user1>> hubot define TRID
hubot>> TRID stands for TILA-RESPA Integrated Disclosure — and TILA-RESPA stands for Truth in Lending Act-Real Estate Settlement Procedures Act
```
[npm-image]: https://img.shields.io/npm/v/hubot-acrogov.svg?maxAge=2592000&style=flat-square
[npm-url]: https://www.npmjs.com/package/hubot-acrogov
[travis-image]: https://img.shields.io/travis/cfpb/hubot-acrogov.svg?maxAge=2592000&style=flat-square
[travis-url]: https://travis-ci.org/cfpb/hubot-acrogov
