import * as cdk from 'aws-cdk-lib/core';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as logs from 'aws-cdk-lib/aws-logs';
import { Construct } from 'constructs';
import * as path from 'path';

export class EvAccountsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // --- Shared: compiled backend code as Lambda asset ---
    const backendDist = path.join(__dirname, '../../backend/dist');

    // Lambda Web Adapter layer — AWS-managed, runs Express on Lambda
    const webAdapterLayer = lambda.LayerVersion.fromLayerVersionArn(
      this,
      'WebAdapterLayer',
      `arn:aws:lambda:${this.region}:753240598075:layer:LambdaAdapterLayerArm64:25`
    );

    // --- API Lambda (Express via Lambda Web Adapter) ---
    const apiFn = new lambda.Function(this, 'ApiFunction', {
      functionName: 'ev-accounts-api',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'run.sh', // Lambda Web Adapter entry
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend'), {
        bundling: {
          image: lambda.Runtime.NODEJS_20_X.bundlingImage,
          command: [
            'bash', '-c',
            'npm ci --omit=dev && npm run build && cp -r dist node_modules package.json /asset-output/',
          ],
        },
      }),
      layers: [webAdapterLayer],
      environment: {
        NODE_ENV: 'production',
        PORT: '3000',
        AWS_LAMBDA_EXEC_WRAPPER: '/opt/bootstrap',
        AWS_LWA_STARTUP_SCRIPT: 'node --dns-result-order=ipv4first dist/lambda/api.js',
        // Secrets added after first deploy via AWS console or CLI
      },
      memorySize: 512,
      timeout: cdk.Duration.seconds(30),
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    // --- HTTP API Gateway ---
    const httpApi = new apigateway.HttpApi(this, 'HttpApi', {
      apiName: 'ev-accounts-api',
      corsPreflight: {
        allowOrigins: ['*'], // Tighten to your frontend domain later
        allowMethods: [apigateway.CorsHttpMethod.ANY],
        allowHeaders: ['*'],
        allowCredentials: true,
      },
    });

    httpApi.addRoutes({
      path: '/{proxy+}',
      methods: [apigateway.HttpMethod.ANY],
      integration: new apigatewayIntegrations.HttpLambdaIntegration(
        'ApiIntegration',
        apiFn
      ),
    });

    // Also handle root path
    httpApi.addRoutes({
      path: '/',
      methods: [apigateway.HttpMethod.ANY],
      integration: new apigatewayIntegrations.HttpLambdaIntegration(
        'ApiRootIntegration',
        apiFn
      ),
    });

    // --- Calibration Lapse Cron (daily at 02:00 UTC) ---
    const calibrationFn = new lambda.Function(this, 'CalibrationCronFunction', {
      functionName: 'ev-accounts-cron-calibration',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'dist/lambda/cron-calibration.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend'), {
        bundling: {
          image: lambda.Runtime.NODEJS_20_X.bundlingImage,
          command: [
            'bash', '-c',
            'npm ci --omit=dev && npm run build && cp -r dist node_modules package.json /asset-output/',
          ],
        },
      }),
      environment: {
        NODE_ENV: 'production',
      },
      memorySize: 256,
      timeout: cdk.Duration.minutes(5),
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    new events.Rule(this, 'CalibrationSchedule', {
      schedule: events.Schedule.cron({ minute: '0', hour: '2' }),
      targets: [new targets.LambdaFunction(calibrationFn)],
    });

    // --- Campaign Finance Cron (every 6 hours) ---
    const campaignFinanceFn = new lambda.Function(this, 'CampaignFinanceCronFunction', {
      functionName: 'ev-accounts-cron-campaign-finance',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'dist/lambda/cron-campaign-finance.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend'), {
        bundling: {
          image: lambda.Runtime.NODEJS_20_X.bundlingImage,
          command: [
            'bash', '-c',
            'npm ci --omit=dev && npm run build && cp -r dist node_modules package.json /asset-output/',
          ],
        },
      }),
      environment: {
        NODE_ENV: 'production',
      },
      memorySize: 256,
      timeout: cdk.Duration.minutes(15), // Finance ingestion can take a while
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    new events.Rule(this, 'CampaignFinanceSchedule', {
      schedule: events.Schedule.rate(cdk.Duration.hours(6)),
      targets: [new targets.LambdaFunction(campaignFinanceFn)],
    });

    // --- SQS Worker Lambda ---
    const sqsWorkerFn = new lambda.Function(this, 'SqsWorkerFunction', {
      functionName: 'ev-accounts-sqs-worker',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      handler: 'dist/lambda/sqs-worker.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../backend'), {
        bundling: {
          image: lambda.Runtime.NODEJS_20_X.bundlingImage,
          command: [
            'bash', '-c',
            'npm ci --omit=dev && npm run build && cp -r dist node_modules package.json /asset-output/',
          ],
        },
      }),
      environment: {
        NODE_ENV: 'production',
      },
      memorySize: 256,
      timeout: cdk.Duration.minutes(15),
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    // If you already have an SQS queue, import it by URL/ARN.
    // Otherwise, create one:
    const ingestQueue = new sqs.Queue(this, 'IngestQueue', {
      queueName: 'ev-accounts-ingest',
      visibilityTimeout: cdk.Duration.minutes(16), // > Lambda timeout
    });

    sqsWorkerFn.addEventSource(
      new lambdaEventSources.SqsEventSource(ingestQueue, {
        batchSize: 1, // Process one adapter at a time
      })
    );

    // --- Frontend: S3 + CloudFront ---
    const frontendBucket = new s3.Bucket(this, 'FrontendBucket', {
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryption: s3.BucketEncryption.S3_MANAGED,
    });

    const distribution = new cloudfront.Distribution(this, 'FrontendCdn', {
      defaultBehavior: {
        origin: origins.S3BucketOrigin.withOriginAccessControl(frontendBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html', // SPA fallback
        },
      ],
    });

    // --- Outputs ---
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      description: 'Backend API URL (API Gateway)',
    });

    new cdk.CfnOutput(this, 'FrontendUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'Frontend URL (CloudFront)',
    });

    new cdk.CfnOutput(this, 'IngestQueueUrl', {
      value: ingestQueue.queueUrl,
      description: 'SQS queue URL for campaign finance ingestion',
    });

    new cdk.CfnOutput(this, 'FrontendBucketName', {
      value: frontendBucket.bucketName,
      description: 'S3 bucket for frontend assets',
    });
  }
}
