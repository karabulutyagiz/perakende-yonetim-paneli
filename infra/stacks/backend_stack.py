from aws_cdk import CfnOutput, Duration, Stack
from aws_cdk import aws_certificatemanager as acm
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_ecr_assets as ecr_assets
from aws_cdk import aws_ecs as ecs
from aws_cdk import aws_ecs_patterns as ecs_patterns
from aws_cdk import aws_elasticloadbalancingv2 as elbv2
from aws_cdk import aws_logs as logs
from aws_cdk import aws_rds as rds
from aws_cdk import aws_s3 as s3
from aws_cdk import aws_secretsmanager as sm
from constructs import Construct


class BackendStack(Stack):
    def __init__(
        self,
        scope: Construct,
        id: str,
        *,
        vpc: ec2.Vpc,
        db: rds.DatabaseInstance,
        db_secret: sm.Secret,
        bucket: s3.Bucket,
        admin_origin: str = "https://admin.gokcetoptan.com",
        certificate_arn: str | None = None,
        **kwargs,
    ) -> None:
        super().__init__(scope, id, **kwargs)

        cluster = ecs.Cluster(self, "EcsCluster", vpc=vpc, container_insights=True)

        jwt_secret = sm.Secret(
            self,
            "JwtSecret",
            description="Gökçe Toptan JWT secret",
            generate_secret_string=sm.SecretStringGenerator(
                password_length=64, exclude_punctuation=True
            ),
        )

        image = ecs.ContainerImage.from_asset(
            "../backend", platform=ecr_assets.Platform.LINUX_AMD64
        )

        # Sertifika verilirse HTTPS listener + HTTP→HTTPS redirect; aksi hâlde düz HTTP.
        certificate = (
            acm.Certificate.from_certificate_arn(self, "BackendCertificate", certificate_arn)
            if certificate_arn
            else None
        )

        fargate = ecs_patterns.ApplicationLoadBalancedFargateService(
            self,
            "BackendService",
            cluster=cluster,
            cpu=512,
            memory_limit_mib=1024,
            desired_count=1,
            public_load_balancer=True,
            certificate=certificate,
            redirect_http=certificate is not None,
            protocol=(
                elbv2.ApplicationProtocol.HTTPS
                if certificate
                else elbv2.ApplicationProtocol.HTTP
            ),
            task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
                image=image,
                container_port=8000,
                log_driver=ecs.LogDrivers.aws_logs(
                    stream_prefix="backend",
                    log_retention=logs.RetentionDays.ONE_MONTH,
                ),
                environment={
                    "APP_ENV": "production",
                    "APP_DEBUG": "false",
                    "AWS_REGION": self.region,
                    "S3_BUCKET": bucket.bucket_name,
                    "BACKEND_CORS_ORIGINS": admin_origin,
                    "DB_HOST": db.db_instance_endpoint_address,
                    "DB_PORT": db.db_instance_endpoint_port,
                    "DB_NAME": "gokce_toptan",
                },
                secrets={
                    "DB_USER": ecs.Secret.from_secrets_manager(db_secret, field="username"),
                    "DB_PASSWORD": ecs.Secret.from_secrets_manager(db_secret, field="password"),
                    "JWT_SECRET": ecs.Secret.from_secrets_manager(jwt_secret),
                },
            ),
            health_check_grace_period=Duration.seconds(60),
        )
        # ALB health check → /health (FastAPI) ; ECS container health check Dockerfile'da.
        fargate.target_group.configure_health_check(
            path="/health",
            healthy_http_codes="200",
            interval=Duration.seconds(30),
            healthy_threshold_count=2,
            unhealthy_threshold_count=3,
        )
        # WebSocket ve yüklemeler için biraz daha uzun idle timeout.
        fargate.load_balancer.set_attribute("idle_timeout.timeout_seconds", "300")

        self.service = fargate.service
        self.load_balancer = fargate.load_balancer

        db.connections.allow_default_port_from(fargate.service)
        bucket.grant_read_write(fargate.task_definition.task_role)

        scheme = "https" if certificate else "http"
        CfnOutput(
            self,
            "BackendUrl",
            value=f"{scheme}://{fargate.load_balancer.load_balancer_dns_name}",
            description="Mobil ve admin panelin API_BASE'ine geçirilecek kök URL (+ /api/v1)",
        )
        CfnOutput(self, "JwtSecretArn", value=jwt_secret.secret_arn)
        CfnOutput(self, "DbSecretArn", value=db_secret.secret_arn)
        CfnOutput(self, "DbEndpoint", value=db.db_instance_endpoint_address)
