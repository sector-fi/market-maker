# Sector Market Maker

## Running Tests

install deps

```
yarn
```

init submodules

```
git submodule update --init --recursive
```

install [foundry](https://github.com/foundry-rs/foundry)

foundry tests:

```
yarn test
```

## Coverage

see coverage stats:

```
yarn coverage
```

install this plugin:
https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters

run `yarn coverage:lcov`
then run `Display Coverage` via Command Pallate
