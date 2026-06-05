# ACTION REQUIRED: Grant npm publish access for @empoweredvote/ev-ui

## What needs to happen

The npm package `@empoweredvote/ev-ui` is owned by the account `chrisandrewsedu`. We need to add `chris.cantrell` as a co-owner so that account can publish new versions.

## One command to run

Log in to npm as `chrisandrewsedu`, then run:

```
npm owner add chris.cantrell @empoweredvote/ev-ui
```

## Verification

Confirm it worked:

```
npm owner ls @empoweredvote/ev-ui
```

You should see both `chrisandrewsedu` and `chris.cantrell` in the output.

## Why this is needed

The `ev-ui` shared component library (used by Essentials, Compass, and other Empowered Vote apps) needs to be updated with a logo link fix. The change is already built and ready to publish as version `0.7.1` — we just need publish rights from the `chris.cantrell` account.

## That's it

Once `npm owner add` is confirmed, no further action is needed from `chrisandrewsedu`. The `chris.cantrell` account will handle the publish.
