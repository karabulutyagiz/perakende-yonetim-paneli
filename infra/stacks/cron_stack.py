from aws_cdk import Stack
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_ecs as ecs
from aws_cdk import aws_events as events
from aws_cdk import aws_events_targets as targets
from constructs import Construct


class CronStack(Stack):
    """Günlük borç durumu yeniden hesaplama cron'u.

    Backend task içindeki `python -m app.scripts.recompute_debts` komutunu
    her gün saat 01:00 Europe/Istanbul olarak tetikler.
    """

    def __init__(
        self,
        scope: Construct,
        id: str,
        *,
        backend_service: ecs.FargateService,
        **kwargs,
    ) -> None:
        super().__init__(scope, id, **kwargs)

        rule = events.Rule(
            self,
            "DailyDebtRecompute",
            schedule=events.Schedule.cron(minute="0", hour="22"),  # UTC 22:00 → TRT 01:00
        )
        rule.add_target(
            targets.EcsTask(
                cluster=backend_service.cluster,
                task_definition=backend_service.task_definition,
                task_count=1,
                # Fargate task'ın egress'e ihtiyacı var (SSM + ECR + RDS DNS).
                subnet_selection=ec2.SubnetSelection(
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
                ),
                assign_public_ip=False,
                container_overrides=[
                    targets.ContainerOverride(
                        container_name=backend_service.task_definition.default_container.container_name,
                        command=["python", "-m", "app.scripts.recompute_debts"],
                    )
                ],
            )
        )
