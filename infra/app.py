#!/usr/bin/env python3
"""AWS CDK giriş noktası — Gökçe Toptan Perakende altyapısı.

Deploy örneği (özel domain + admin origin):
    cdk deploy --all -c admin_origin=https://admin.example.com
"""
import os

import aws_cdk as cdk

from stacks.backend_stack import BackendStack
from stacks.cron_stack import CronStack
from stacks.database_stack import DatabaseStack
from stacks.frontend_stack import FrontendStack
from stacks.network_stack import NetworkStack
from stacks.storage_stack import StorageStack

env = cdk.Environment(
    account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
    region=os.environ.get("CDK_DEFAULT_REGION", "eu-central-1"),
)

app = cdk.App()

# admin_origin: CORS whitelisting için gerekli. İlk deploy'dan sonra CloudFront domain'i
# burada override edilir. Context ile ver: `cdk deploy -c admin_origin=https://d1abc.cloudfront.net`
admin_origin: str = app.node.try_get_context("admin_origin") or "*"
# Opsiyonel: ACM sertifikası varsa ALB'ye HTTPS listener takılır ve HTTP→HTTPS redirect açılır.
# `cdk deploy -c backend_certificate_arn=arn:aws:acm:...`
backend_certificate_arn: str | None = app.node.try_get_context("backend_certificate_arn")

network = NetworkStack(app, "GokceNetwork", env=env)
storage = StorageStack(app, "GokceStorage", admin_origin=admin_origin, env=env)
database = DatabaseStack(app, "GokceDatabase", vpc=network.vpc, env=env)
backend = BackendStack(
    app,
    "GokceBackend",
    vpc=network.vpc,
    db=database.cluster,
    db_secret=database.secret,
    bucket=storage.bucket,
    admin_origin=admin_origin,
    certificate_arn=backend_certificate_arn,
    env=env,
)
frontend = FrontendStack(app, "GokceFrontend", env=env)
cron = CronStack(app, "GokceCron", backend_service=backend.service, env=env)

cdk.Tags.of(app).add("project", "gokce-toptan")
cdk.Tags.of(app).add("owner", "gokce-toptan-perakende")

app.synth()
