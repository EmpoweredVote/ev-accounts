#!/opt/homebrew/opt/node/bin/node
import * as cdk from 'aws-cdk-lib/core';
import { EvAccountsStack } from '../lib/infra-stack';

const app = new cdk.App();
new EvAccountsStack(app, 'EvAccountsStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
