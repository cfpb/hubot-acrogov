# hubot-acrogov

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


