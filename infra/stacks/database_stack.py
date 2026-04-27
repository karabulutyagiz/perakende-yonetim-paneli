from aws_cdk import Duration, RemovalPolicy, Stack
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_rds as rds
from aws_cdk import aws_secretsmanager as sm
from constructs import Construct


class DatabaseStack(Stack):
    def __init__(self, scope: Construct, id: str, vpc: ec2.Vpc, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        self.secret = sm.Secret(
            self,
            "DbSecret",
            description="Gökçe Toptan RDS credentials",
            generate_secret_string=sm.SecretStringGenerator(
                secret_string_template='{"username":"gokce"}',
                generate_string_key="password",
                exclude_characters='"@/\\ ',
                password_length=32,
            ),
        )

        self.cluster = rds.DatabaseInstance(
            self,
            "GokcePostgres",
            engine=rds.DatabaseInstanceEngine.postgres(
                version=rds.PostgresEngineVersion.VER_16_3
            ),
            vpc=vpc,
            vpc_subnets=ec2.SubnetSelection(
                subnet_type=ec2.SubnetType.PRIVATE_ISOLATED
            ),
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO
            ),
            allocated_storage=20,
            max_allocated_storage=100,
            storage_encrypted=True,
            multi_az=False,
            credentials=rds.Credentials.from_secret(self.secret),
            database_name="gokce_toptan",
            backup_retention=Duration.days(7),
            delete_automated_backups=False,
            deletion_protection=True,
            removal_policy=RemovalPolicy.RETAIN,
            publicly_accessible=False,
            auto_minor_version_upgrade=True,
        )
